//
//  LocalAssistantService.swift
//  What Now?
//

import Foundation

enum LocalConversationState: Equatable {
    case idle
    case creatingTask(title: String, date: Date?, duration: Int?, priority: TaskPriority?, dateResolved: Bool)
}

final class LocalAssistantService: AIServiceProtocol {
    private let taskService: TaskService
    private let planService: PlanService
    private let memoryService: MemoryService
    private let preferenceService: PreferenceService
    
    private var state: LocalConversationState = .idle
    
    init(taskService: TaskService, planService: PlanService, memoryService: MemoryService, preferenceService: PreferenceService) {
        self.taskService = taskService
        self.planService = planService
        self.memoryService = memoryService
        self.preferenceService = preferenceService
    }
    
    var isAwaitingClarification: Bool {
        return state != .idle
    }
    
    func injectIntent(_ intent: AIAssistantIntent) {
        // Can be used to explicitly clear state if needed.
    }
    
    func processQuery(_ query: String, history: [AIChatMessage], context: String) async throws -> AIAssistantIntent {
        let lower = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle cancel
        if lower == "cancel" || lower == "stop" || lower == "nevermind" || lower == "× cancel" {
            if state != .idle {
                state = .idle
                return .chatResponse(message: "Okay, cancelled.")
            }
        }
        
        // 1. Check if we are in the middle of a task creation flow
        if case .creatingTask(let title, let date, let duration, let priority, let dateResolved) = state {
            return processTaskCreationState(
                query: text,
                lower: lower,
                title: title,
                date: date,
                duration: duration,
                priority: priority,
                dateResolved: dateResolved
            )
        }
        
        // 2. Check explicitly triggered local commands
        if lower.hasPrefix("add ") || lower.hasPrefix("create ") || lower.hasPrefix("schedule ") {
            return processNewTaskCommand(query: text)
        }
        
        // Return error to let the IntelligenceRouter fall back to External AI
        throw NSError(domain: "LocalAssistant", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not a deterministic local command."])
    }
    
    func processFallback(query: String) async throws -> AIAssistantIntent {
        let lower = query.lowercased()
        
        // Replan
        if lower.contains("replan") || lower.contains("plan my day") || lower.contains("plan my evening") || lower.contains("plan my morning") {
            return .planDay
        }
        
        // Start focus
        if lower.hasPrefix("start ") {
            let fragment = String(query.dropFirst("start ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return .startFocus(taskTitleFragment: fragment)
        }
        if lower.hasPrefix("help me finish ") {
            let fragment = String(query.dropFirst("help me finish ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return .startFocus(taskTitleFragment: fragment)
        }
        if lower.hasPrefix("focus on ") {
            let fragment = String(query.dropFirst("focus on ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return .startFocus(taskTitleFragment: fragment)
        }
        
        // What's next / recommendations
        if lower.contains("what's next") || lower.contains("recommend") || lower.contains("what should i do") || lower.contains("what now") {
            return .getRecommendations
        }
        
        // Memory commands
        if let memoryAction = NaturalLanguageTaskParser.parseMemoryCommand(query) {
            switch memoryAction {
            case .remember(let fact):
                return .remember(fact: fact)
            case .forgetAll:
                return .chatResponse(message: "SYSTEM_FORGET_ALL")
            case .query:
                return .chatResponse(message: "SYSTEM_QUERY_MEMORY")
            }
        }
        
        // Attempt a general task parse if nothing else matches
        return processNewTaskCommand(query: query)
    }
    
    // MARK: - State Machine Handlers
    
    private func processNewTaskCommand(query: String) -> AIAssistantIntent {
        let parsed = NaturalLanguageTaskParser.parse(query)
        if parsed.title.isEmpty {
            return .chatResponse(message: "I didn't quite catch what you wanted to add.")
        }
        
        // If we already have all the info, create immediately
        let dateResolved = parsed.deadline != nil
        state = .creatingTask(
            title: parsed.title,
            date: parsed.deadline,
            duration: parsed.estimatedMinutes,
            priority: parsed.priority,
            dateResolved: dateResolved
        )
        
        return advanceStateMachine()
    }
    
    private func processTaskCreationState(
        query: String,
        lower: String,
        title: String,
        date: Date?,
        duration: Int?,
        priority: TaskPriority?,
        dateResolved: Bool
    ) -> AIAssistantIntent {
        var newDate = date
        var newDuration = duration
        var newPriority = priority
        var newDateResolved = dateResolved
        
        if !dateResolved {
            // We are waiting for date answer
            if let d = parseDateOption(lower) {
                newDate = d
                newDateResolved = true
            } else if lower == "no date" || lower == "later" || lower == "skip" || lower == "none" {
                // User skipped date — treat as no specific date (nil)
                newDate = nil
                newDateResolved = true
            } else {
                // Try NL parser as fallback
                let parsed = NaturalLanguageTaskParser.parse(query)
                if let d = parsed.deadline {
                    newDate = d
                    newDateResolved = true
                }
            }
        } else if newDuration == nil {
            // We are waiting for duration answer
            if let d = parseDurationOption(lower) {
                newDuration = d
            } else if lower == "default" || lower == "skip" {
                newDuration = preferenceService.profile.preferredFocusMinutes
            } else {
                // Try NL parser
                if let d = NaturalLanguageTaskParser.parseDuration(from: lower) {
                    newDuration = d
                } else if let num = Int(lower.filter { $0.isNumber }), num > 0 {
                    // Direct number entry
                    newDuration = num
                } else {
                    // Use default if unparseable
                    newDuration = preferenceService.profile.preferredFocusMinutes
                }
            }
        } else if newPriority == nil {
            // We are waiting for priority answer
            if let p = parsePriorityOption(lower) {
                newPriority = p
            } else {
                // Default to medium if unparseable
                newPriority = .medium
            }
        }
        
        state = .creatingTask(title: title, date: newDate, duration: newDuration, priority: newPriority, dateResolved: newDateResolved)
        return advanceStateMachine()
    }
    
    private func advanceStateMachine() -> AIAssistantIntent {
        guard case .creatingTask(let title, let date, let duration, _, let dateResolved) = state else {
            return .chatResponse(message: "Conversation state error.")
        }
        
        // 1. Need Date? (only ask if not yet resolved)
        if !dateResolved {
            return .askQuestion(
                prompt: "When would you like to do '\(title)'?",
                options: ["Today", "Tomorrow", "Later", "No Date"],
                expectedField: "date"
            )
        }
        
        // 2. Need Duration?
        if duration == nil {
            return .askQuestion(
                prompt: "How long should I plan for?",
                options: ["15m", "30m", "45m", "1h", "Default"],
                expectedField: "duration"
            )
        }
        
        // 3. All collected — skip priority question, use parsed priority or default
        state = .idle
        return .createTask(title: title, durationMinutes: duration, deadline: date)
    }
    
    // MARK: - Option Parsers
    
    /// Parses user-tapped date options like "Today", "Tomorrow", "Later", "No Date"
    private func parseDateOption(_ lower: String) -> Date? {
        let now = Date.now
        switch lower {
        case "today":
            return Calendar.current.startOfDay(for: now)
        case "tomorrow":
            return Calendar.current.date(byAdding: .day, value: 1, to: now)
        default:
            return nil
        }
    }
    
    /// Parses user-tapped duration options like "15m", "30m", "45m", "1h"
    private func parseDurationOption(_ lower: String) -> Int? {
        switch lower {
        case "15m", "15 min", "15 minutes": return 15
        case "30m", "30 min", "30 minutes": return 30
        case "45m", "45 min", "45 minutes": return 45
        case "1h", "1 hour", "60m", "60 min": return 60
        case "2h", "2 hours": return 120
        case "default": return preferenceService.profile.preferredFocusMinutes
        default:
            // Try the general parser
            return NaturalLanguageTaskParser.parseDuration(from: lower)
        }
    }
    
    /// Parses user-tapped priority options like "High", "Medium", "Low"
    private func parsePriorityOption(_ lower: String) -> TaskPriority? {
        switch lower {
        case "high", "urgent", "critical": return .high
        case "medium", "normal", "mid": return .medium
        case "low": return .low
        default: return nil
        }
    }
}
