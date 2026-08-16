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

        if let minutes = firstInteger(before: "min", in: lower) ?? firstInteger(before: "minute", in: lower) {
            result.estimatedMinutes = minutes
        }
        if lower.contains("night") || lower.contains("evening") || lower.contains("pm") { result.preferredTime = .evening }
        else if lower.contains("morning") || lower.contains("am") { result.preferredTime = .morning }
        else if lower.contains("afternoon") { result.preferredTime = .afternoon }
        
        if lower.contains("high priority") || lower.contains("urgent") || lower.contains("critical") { result.priority = .high }
        else if lower.contains("low priority") { result.priority = .low }

        return result
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
        let markers = [" every ", " weekdays", " weekends", " tomorrow", " today", " weekly", " monthly", " monday", " tuesday", " wednesday", " thursday", " friday", " saturday", " sunday", " for "]
        let prefixes = ["add ", "create ", "schedule ", "remind me to ", "task "]
        
        var lower = value.lowercased()
        var startIdx = value.startIndex
        
        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                startIdx = value.index(value.startIndex, offsetBy: prefix.count)
                lower = String(lower[startIdx...])
                break
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
