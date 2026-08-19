//
//  LocalAssistantService.swift
//  What Now?
//

import Foundation

enum LocalConversationState: Equatable {
    case idle
    case creatingTask(
        title: String,
        date: Date?,
        time: TimeOfDay?,
        duration: Int?,
        priority: TaskPriority?,
        dateResolved: Bool,
        timeResolved: Bool,
        durationResolved: Bool
    )
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
        if case .creatingTask(let title, let date, let time, let duration, let priority, let dateResolved, let timeResolved, let durationResolved) = state {
            return processTaskCreationState(
                query: text,
                lower: lower,
                title: title,
                date: date,
                time: time,
                duration: duration,
                priority: priority,
                dateResolved: dateResolved,
                timeResolved: timeResolved,
                durationResolved: durationResolved
            )
        }
        
        // 2. Check explicitly triggered local commands
        if lower.hasPrefix("add ") || lower.hasPrefix("create ") || lower.hasPrefix("schedule ") {
            return processNewTaskCommand(query: text)
        }
        
        // 3. Replan command
        if lower.contains("replan") || lower.contains("plan my day") || lower.contains("plan my evening") || lower.contains("plan my morning") {
            return .planDay
        }
        
        // 4. Start command
        if lower.hasPrefix("start ") || lower.hasPrefix("begin ") {
            let prefix = lower.hasPrefix("start ") ? "start " : "begin "
            let fragment = String(query.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return .startFocus(taskTitleFragment: fragment)
        }
        
        // 5. Move/Change command
        if lower.hasPrefix("move ") || lower.hasPrefix("change ") {
            // Very naive local modification extraction: "move [task] to [time]"
            let components = lower.components(separatedBy: " to ")
            if components.count == 2 {
                let taskFragment = String(components[0].dropFirst(lower.hasPrefix("move ") ? 5 : 7)).trimmingCharacters(in: .whitespacesAndNewlines)
                let timeFragment = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Parse specific hour
                let pattern = #"(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: timeFragment, range: NSRange(timeFragment.startIndex..., in: timeFragment)) {
                    
                    var hour = Int(timeFragment[Range(match.range(at: 1), in: timeFragment)!]) ?? 0
                    if let modRange = Range(match.range(at: 3), in: timeFragment) {
                        let modifier = String(timeFragment[modRange])
                        if modifier == "pm" && hour < 12 { hour += 12 }
                        else if modifier == "am" && hour == 12 { hour = 0 }
                    } else if hour < 6 { hour += 12 }
                    
                    if let newStart = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) {
                        let iso = ISO8601DateFormatter().string(from: newStart)
                        return .modifyPlan(actions: [PlanModification(originalTitleFragment: taskFragment, newStartTimeIso: iso, newDurationMinutes: nil)])
                    }
                }
            }
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
        // Move/Change command
        if lower.hasPrefix("move ") || lower.hasPrefix("change ") {
            let components = lower.components(separatedBy: " to ")
            if components.count == 2 {
                let taskFragment = String(components[0].dropFirst(lower.hasPrefix("move ") ? 5 : 7)).trimmingCharacters(in: .whitespacesAndNewlines)
                let timeFragment = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                let pattern = #"(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: timeFragment, range: NSRange(timeFragment.startIndex..., in: timeFragment)) {
                    
                    var hour = Int(timeFragment[Range(match.range(at: 1), in: timeFragment)!]) ?? 0
                    if let modRange = Range(match.range(at: 3), in: timeFragment) {
                        let modifier = String(timeFragment[modRange])
                        if modifier == "pm" && hour < 12 { hour += 12 }
                        else if modifier == "am" && hour == 12 { hour = 0 }
                    } else if hour < 6 { hour += 12 }
                    
                    if let newStart = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) {
                        let iso = ISO8601DateFormatter().string(from: newStart)
                        return .modifyPlan(actions: [PlanModification(originalTitleFragment: taskFragment, newStartTimeIso: iso, newDurationMinutes: nil)])
                    }
                }
            }
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
        
        // Attempt generic task creation as a final fallback ("Gym at 6", "Study for an hour")
        let taskIntent = processNewTaskCommand(query: query)
        if case .chatResponse(let msg) = taskIntent, msg == "I didn't quite catch what you wanted to add. What should I call it?" {
            throw NSError(domain: "LocalAssistant", code: 404, userInfo: [NSLocalizedDescriptionKey: "Unrecognized offline intent."])
        }
        return taskIntent
    }
    
    private func processNewTaskCommand(query: String) -> AIAssistantIntent {
        let parsed = NaturalLanguageTaskParser.parse(query)
        if parsed.title.isEmpty {
            return .chatResponse(message: "I didn't quite catch what you wanted to add. What should I call it?")
        }
        
        let dateResolved = parsed.deadline != nil
        
        var timeResolved = parsed.preferredTime != nil
        if let deadline = parsed.deadline {
            let components = Calendar.current.dateComponents([.hour, .minute], from: deadline)
            if (components.hour ?? 0) != 0 || (components.minute ?? 0) != 0 {
                timeResolved = true
            }
        }
        
        let durationResolved = parsed.estimatedMinutes != nil
        
        state = .creatingTask(
            title: parsed.title,
            date: parsed.deadline,
            time: parsed.preferredTime,
            duration: parsed.estimatedMinutes,
            priority: parsed.priority,
            dateResolved: dateResolved,
            timeResolved: timeResolved,
            durationResolved: durationResolved
        )
        
        return advanceStateMachine()
    }
    
    private func processTaskCreationState(
        query: String,
        lower: String,
        title: String,
        date: Date?,
        time: TimeOfDay?,
        duration: Int?,
        priority: TaskPriority?,
        dateResolved: Bool,
        timeResolved: Bool,
        durationResolved: Bool
    ) -> AIAssistantIntent {
        var newDate = date
        var newTime = time
        var newDuration = duration
        let newPriority = priority
        var newDateResolved = dateResolved
        var newTimeResolved = timeResolved
        var newDurationResolved = durationResolved
        
        // --- Correction Engine ---
        let isCorrection = lower.hasPrefix("actually ") || lower.hasPrefix("change ") || lower.hasPrefix("make that ") || lower.hasPrefix("no ")
        if isCorrection {
            let stripped = lower.replacingOccurrences(of: "actually ", with: "")
                                .replacingOccurrences(of: "change that to ", with: "")
                                .replacingOccurrences(of: "make that ", with: "")
                                .replacingOccurrences(of: "no ", with: "")
            
            let parsed = NaturalLanguageTaskParser.parse(stripped)
            var corrected = false
            
            if let d = parseDateOption(stripped) ?? parsed.deadline {
                newDate = d
                newDateResolved = true
                corrected = true
            }
            if let t = parseTimeOption(stripped) ?? parsed.preferredTime {
                newTime = t
                newTimeResolved = true
                corrected = true
            }
            if let dur = parseDurationOption(stripped) ?? parsed.estimatedMinutes {
                newDuration = dur
                newDurationResolved = true
                corrected = true
            }
            
            if corrected {
                state = .creatingTask(
                    title: title,
                    date: newDate,
                    time: newTime,
                    duration: newDuration,
                    priority: newPriority,
                    dateResolved: newDateResolved,
                    timeResolved: newTimeResolved,
                    durationResolved: newDurationResolved
                )
                return advanceStateMachine()
            }
        }
        // --- End Correction Engine ---
        
        if !dateResolved {
            if let d = parseDateOption(lower) {
                newDate = d
                newDateResolved = true
            } else if lower == "no date" || lower == "later" || lower == "skip" || lower == "none" {
                newDate = nil
                newDateResolved = true
                newTimeResolved = true // Skip time if no date
            } else {
                let parsed = NaturalLanguageTaskParser.parse(query)
                if let d = parsed.deadline {
                    newDate = d
                    newDateResolved = true
                }
            }
        } else if !timeResolved {
            if let t = parseTimeOption(lower) {
                newTime = t
                newTimeResolved = true
            } else if lower == "any time" || lower == "skip" {
                newTime = nil
                newTimeResolved = true
            } else {
                let parsed = NaturalLanguageTaskParser.parse(query)
                if let t = parsed.preferredTime {
                    newTime = t
                    newTimeResolved = true
                } else if parsed.deadline != nil {
                    // They might have typed "at 7pm"
                    newDate = parsed.deadline
                    newTimeResolved = true
                }
            }
        } else if !durationResolved {
            if let d = parseDurationOption(lower) {
                newDuration = d
                newDurationResolved = true
            } else if lower == "default" || lower == "skip" {
                newDuration = preferenceService.profile.preferredFocusMinutes
                newDurationResolved = true
            } else if let d = NaturalLanguageTaskParser.parseDuration(from: lower) {
                newDuration = d
                newDurationResolved = true
            } else if let num = Int(lower.filter { $0.isNumber }), num > 0 {
                newDuration = num
                newDurationResolved = true
            } else {
                newDuration = preferenceService.profile.preferredFocusMinutes
                newDurationResolved = true
            }
        } else {
            // Should not happen, but fallback
            state = .idle
            return .chatResponse(message: "Done.")
        }
        
        state = .creatingTask(
            title: title,
            date: newDate,
            time: newTime,
            duration: newDuration,
            priority: newPriority,
            dateResolved: newDateResolved,
            timeResolved: newTimeResolved,
            durationResolved: newDurationResolved
        )
        return advanceStateMachine()
    }
    
    private func advanceStateMachine() -> AIAssistantIntent {
        guard case .creatingTask(let title, let date, let time, let duration, _, let dateResolved, let timeResolved, let durationResolved) = state else {
            return .chatResponse(message: "Conversation state error.")
        }
        
        if !dateResolved {
            return .askQuestion(
                prompt: "When would you like to do it?",
                options: ["Today", "Tomorrow", "Later", "No Date"],
                expectedField: "date"
            )
        }
        
        if !timeResolved {
            return .askQuestion(
                prompt: "What time works?",
                options: ["Morning", "Afternoon", "Evening", "Any Time"],
                expectedField: "time"
            )
        }
        
        if !durationResolved {
            let prefStr = "\(preferenceService.profile.preferredFocusMinutes)m"
            let options = ["15m", "30m", "45m", "1h", "Custom"].map { $0 == prefStr ? "[\($0)]" : $0 }
            return .askQuestion(
                prompt: "How long should I plan for?",
                options: options, // Highlight default but don't force
                expectedField: "duration"
            )
        }
        
        // All collected
        state = .idle
        
        // Merge TimeOfDay into Date if Date exists but is just midnight
        var finalDate = date
        if let d = date, let t = time {
            // Very simplified: just use the morning/afternoon/evening hours
            let calendar = Calendar.current
            var hour = 12
            switch t {
            case .morning: hour = 9
            case .afternoon: hour = 14
            case .evening: hour = 19
            case .anytime: hour = 12
            }
            finalDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: d) ?? d
        }
        
        return .createTask(title: title, durationMinutes: duration, deadline: finalDate)
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
    
    private func parseTimeOption(_ lower: String) -> TimeOfDay? {
        if lower.contains("morning") { return .morning }
        if lower.contains("afternoon") { return .afternoon }
        if lower.contains("evening") || lower.contains("night") { return .evening }
        return nil
    }
    
    private func parseDurationOption(_ lower: String) -> Int? {
        let unbracketed = lower.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
        switch unbracketed {
        case "15m", "15 min", "15 minutes": return 15
        case "30m", "30 min", "30 minutes": return 30
        case "45m", "45 min", "45 minutes": return 45
        case "1h", "1 hour", "60m", "60 min": return 60
        case "2h", "2 hours": return 120
        case "custom": return nil // Will fall back to typing Custom number
        default:
            return NaturalLanguageTaskParser.parseDuration(from: lower)
        }
    }
}
