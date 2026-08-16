//
//  LocalAssistantService.swift
//  What Now?
//

import Foundation

enum LocalConversationState: Equatable {
    case idle
    case creatingTask(title: String, date: Date?, duration: Int?, priority: TaskPriority?)
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
    
    func injectIntent(_ intent: AIAssistantIntent) {
        // Unused for now, can be used to explicitly clear state if needed.
    }
    
    func processQuery(_ query: String, history: [AIChatMessage], context: String) async throws -> AIAssistantIntent {
        let lower = query.lowercased()
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Check if we are in the middle of a task creation flow
        if case .creatingTask(let title, let date, let duration, let priority) = state {
            return processTaskCreationState(query: lower, title: title, date: date, duration: duration, priority: priority)
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
        
        if lower.contains("replan") || lower.contains("plan my day") {
            return .planDay
        } else if lower.contains("what's next") || lower.contains("recommend") || lower.contains("what should i do") {
            return .getRecommendations
        } else if let memoryAction = NaturalLanguageTaskParser.parseMemoryCommand(query) {
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
        
        state = .creatingTask(title: parsed.title, date: parsed.deadline, duration: parsed.estimatedMinutes, priority: nil)
        
        return advanceStateMachine()
    }
    
    private func processTaskCreationState(query: String, title: String, date: Date?, duration: Int?, priority: TaskPriority?) -> AIAssistantIntent {
        var newDate = date
        var newDuration = duration
        var newPriority = priority
        
        // We look at the query to extract what's missing
        let parsed = NaturalLanguageTaskParser.parse(query)
        
        if newDate == nil {
            newDate = parsed.deadline
        } else if newDuration == nil {
            newDuration = parsed.estimatedMinutes ?? (Int(query.filter { $0.isNumber }) ?? nil)
            // Smart default fallback: if they just tapped "Skip" or provided unparseable text, 
            // use their preferred focus duration.
            if newDuration == nil {
                newDuration = preferenceService.profile.preferredFocusMinutes
            }
        } else if newPriority == nil {
            if query.contains("high") || query.contains("urgent") || query.contains("critical") {
                newPriority = .high
            } else if query.contains("low") {
                newPriority = .low
            } else {
                newPriority = .medium
            }
        }
        
        state = .creatingTask(title: title, date: newDate, duration: newDuration, priority: newPriority)
        return advanceStateMachine()
    }
    
    private func advanceStateMachine() -> AIAssistantIntent {
        guard case .creatingTask(let title, let date, let duration, let priority) = state else {
            return .chatResponse(message: "Conversation state error.")
        }
        
        // 1. Need Date?
        if date == nil {
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
        
        // 3. Need Priority?
        if priority == nil {
            return .askQuestion(
                prompt: "What priority?",
                options: ["Low", "Medium", "High"],
                expectedField: "priority"
            )
        }
        
        // All collected! Create task.
        state = .idle
        return .createTask(title: title, durationMinutes: duration, deadline: date)
    }
}
