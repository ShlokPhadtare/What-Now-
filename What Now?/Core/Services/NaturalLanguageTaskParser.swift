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
    }

    static func parse(_ input: String, now: Date = .now) -> Result {
        let lower = input.lowercased()
        var result = Result(title: cleanedTitle(from: input), repeatSchedule: nil, deadline: nil, estimatedMinutes: nil, preferredTime: nil)

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
        let lower = value.lowercased()
        let end = markers.compactMap { lower.range(of: $0)?.lowerBound }.min() ?? value.endIndex
        return String(value[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
