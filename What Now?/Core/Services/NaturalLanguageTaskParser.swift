//
//  NaturalLanguageTaskParser.swift
//  What Now?
//

import Foundation

/// Small deterministic parser for fast task entry. It deliberately only fills facts it can infer.
enum NaturalLanguageTaskParser {
    struct Result {
        var title: String
        var repeatSchedule: RepeatSchedule?
        var deadline: Date?
        var estimatedMinutes: Int?
        var preferredTime: TimeOfDay?
        var priority: TaskPriority?
    }

    static func parse(_ input: String, now: Date = .now) -> Result {
        let lower = input.lowercased()
        var result = Result(title: cleanedTitle(from: input), repeatSchedule: nil, deadline: nil, estimatedMinutes: nil, preferredTime: nil, priority: nil)

        if lower.contains("every weekday") || lower.contains("weekdays") { result.repeatSchedule = .weekdays }
        else if lower.contains("every weekend") || lower.contains("weekends") { result.repeatSchedule = .weekends }
        else if lower.contains("every day") || lower.contains("daily") { result.repeatSchedule = .daily }
        else if lower.contains("weekly") { result.repeatSchedule = .weekly(anchor: now) }
        else if lower.contains("monthly") { result.repeatSchedule = .monthly(anchor: now) }
        else {
            let weekdays = weekdayMatches(in: lower)
            if weekdays.count > 1 { result.repeatSchedule = .custom(days: weekdays) }
            else if let weekday = weekdays.first { result.repeatSchedule = .custom(days: [weekday]) }
        }

        if lower.contains("tomorrow") {
            result.deadline = Calendar.current.date(byAdding: .day, value: 1, to: now)
        } else if lower.contains("today") {
            result.deadline = now
        }
        
        // Extract specific time (e.g., "at 7pm", "at 7:30pm", "at 19:00")
        if let specificHour = parseSpecificHour(from: lower) {
            let base = result.deadline ?? now
            if let withHour = Calendar.current.date(bySettingHour: specificHour, minute: 0, second: 0, of: base) {
                result.deadline = withHour
            }
        }

        // Duration parsing — supports: "30 min", "30 minute", "30m", "1h", "2h", "1 hour"
        if let minutes = parseDuration(from: lower) {
            result.estimatedMinutes = minutes
        }
        
        if lower.contains("night") || lower.contains("evening") || lower.contains(" pm") { result.preferredTime = .evening }
        else if lower.contains("morning") || lower.contains(" am") { result.preferredTime = .morning }
        else if lower.contains("afternoon") { result.preferredTime = .afternoon }
        
        if lower.contains("high priority") || lower.contains("urgent") || lower.contains("critical") { result.priority = .high }
        else if lower.contains("low priority") { result.priority = .low }

        return result
    }
    
    /// Parse duration from common patterns: "30 min", "30m", "1h", "1 hour", "45 minutes"
    static func parseDuration(from lower: String) -> Int? {
        // Match "X hour" or "Xh"
        let hourPattern = #"\b(\d{1,2})\s*h(?:our)?s?\b"#
        if let regex = try? NSRegularExpression(pattern: hourPattern),
           let match = regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)),
           let range = Range(match.range(at: 1), in: lower),
           let hours = Int(lower[range]) {
            return hours * 60
        }
        
        // Match "X min", "X minute", "Xm" (standalone, not part of a word)
        let minPattern = #"\b(\d{1,3})\s*m(?:in(?:ute)?s?)?\b"#
        if let regex = try? NSRegularExpression(pattern: minPattern),
           let match = regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)),
           let range = Range(match.range(at: 1), in: lower),
           let mins = Int(lower[range]) {
            return mins
        }
        
        return nil
    }
    
    /// Parse "at 7pm", "at 7:30 pm", "at 19:00" → returns the hour (24h)
    private static func parseSpecificHour(from lower: String) -> Int? {
        // Match "at 7pm", "at 7 pm"
        let pattern = #"\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)) else { return nil }
        
        guard let hourRange = Range(match.range(at: 1), in: lower),
              var hour = Int(lower[hourRange]) else { return nil }
        
        // Handle am/pm
        if let modifierRange = Range(match.range(at: 3), in: lower) {
            let modifier = String(lower[modifierRange])
            if modifier == "pm" && hour < 12 { hour += 12 }
            else if modifier == "am" && hour == 12 { hour = 0 }
        } else if hour < 6 {
            // Ambiguous, assume PM for hours < 6 with no am/pm
            hour += 12
        }
        
        return hour
    }

    private static func weekdayMatches(in value: String) -> Set<Int> {
        let names: [(String, Int)] = [("sunday", 1), ("monday", 2), ("tuesday", 3), ("wednesday", 4), ("thursday", 5), ("friday", 6), ("saturday", 7)]
        return Set(names.compactMap { value.contains($0.0) ? $0.1 : nil })
    }

    private static func firstInteger(before suffix: String, in value: String) -> Int? {
        let pattern = #"\b(\d{1,3})\s*"# + suffix
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
              let range = Range(match.range(at: 1), in: value)
        else { return nil }
        return Int(value[range])
    }

    private static func cleanedTitle(from value: String) -> String {
        let markers = [" every ", " weekdays", " weekends", " tomorrow", " today", " weekly", " monthly", " monday", " tuesday", " wednesday", " thursday", " friday", " saturday", " sunday", " for ", " at "]
        let prefixes = [
            "add ", "create ", "schedule ", "remind me to ", "task ",
            "i need to ", "i want to ", "i have to ", "please ", "can you ", "could you "
        ]
        
        var lower = value.lowercased()
        var startIdx = value.startIndex
        
        var prefixFound = true
        while prefixFound {
            prefixFound = false
            for prefix in prefixes {
                if lower.hasPrefix(prefix) {
                    startIdx = value.index(startIdx, offsetBy: prefix.count)
                    lower = String(lower.dropFirst(prefix.count))
                    prefixFound = true
                    break
                }
            }
        }
        
        let subValue = String(value[startIdx...])
        let end = markers.compactMap { lower.range(of: $0)?.lowerBound }.min() ?? lower.endIndex
        
        var finalTitle = String(subValue[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Strip out priority keywords from the end if they exist
        let suffixesToRemove = [" high priority", " urgent", " critical", " low priority"]
        for s in suffixesToRemove {
            if finalTitle.lowercased().hasSuffix(s) {
                finalTitle.removeLast(s.count)
                finalTitle = finalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // If the title is empty after stripping, just use the original value as a fallback
        if finalTitle.isEmpty {
            finalTitle = value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return finalTitle
    }
    
    // MARK: - Memory Parsing
    
    enum MemoryAction {
        case remember(fact: String)
        case forgetAll
        case query
    }
    
    static func parseMemoryCommand(_ input: String) -> MemoryAction? {
        let lower = input.lowercased()
        
        if lower.contains("forget everything") || lower.contains("clear memory") || lower.contains("clear memories") {
            return .forgetAll
        }
        
        if lower.contains("what do you remember") || lower.contains("what do i prefer") {
            return .query
        }
        
        // "Remember that I like apples" -> "I like apples"
        // "Remember I prefer evenings" -> "I prefer evenings"
        if let range = lower.range(of: "remember that ") {
            let fact = String(input[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !fact.isEmpty { return .remember(fact: fact) }
        }
        if let range = lower.range(of: "remember ") {
            let fact = String(input[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !fact.isEmpty { return .remember(fact: fact) }
        }
        
        return nil
    }
}
