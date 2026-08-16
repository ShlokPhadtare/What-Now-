//
//  RepeatSchedule.swift
//  What Now?
//

import Foundation

/// Defines how a task or routine repeats.
enum RepeatFrequency: String, Codable, CaseIterable, Identifiable, Sendable {
    case daily
    case weekdays
    case weekends
    case weekly
    case monthly
    case everyXDays
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: "Every Day"
        case .weekdays: "Weekdays"
        case .weekends: "Weekends"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .everyXDays: "Every X Days"
        case .custom: "Custom"
        }
    }
}

/// Full repeat schedule configuration, stored as JSON Data in SwiftData models.
nonisolated struct RepeatSchedule: Codable, Equatable, Sendable {
    let frequency: RepeatFrequency

    /// Specific days of the week (1 = Sunday, 7 = Saturday).
    /// Only used when `frequency == .custom`.
    let customDays: Set<Int>?
    /// The first occurrence. It fixes weekly/monthly schedules and every-X-day intervals.
    let anchorDate: Date?
    let intervalDays: Int?

    /// Standard presets for quick creation.
    static let daily = RepeatSchedule(frequency: .daily, customDays: nil, anchorDate: nil, intervalDays: nil)
    static let weekdays = RepeatSchedule(frequency: .weekdays, customDays: nil, anchorDate: nil, intervalDays: nil)
    static let weekends = RepeatSchedule(frequency: .weekends, customDays: nil, anchorDate: nil, intervalDays: nil)
    static func weekly(anchor: Date = .now) -> RepeatSchedule {
        RepeatSchedule(frequency: .weekly, customDays: nil, anchorDate: anchor, intervalDays: nil)
    }
    static func monthly(anchor: Date = .now) -> RepeatSchedule {
        RepeatSchedule(frequency: .monthly, customDays: nil, anchorDate: anchor, intervalDays: nil)
    }
    static func every(_ days: Int, anchor: Date = .now) -> RepeatSchedule {
        RepeatSchedule(frequency: .everyXDays, customDays: nil, anchorDate: anchor, intervalDays: max(1, days))
    }

    static func custom(days: Set<Int>) -> RepeatSchedule {
        RepeatSchedule(frequency: .custom, customDays: days, anchorDate: nil, intervalDays: nil)
    }

    /// Returns the set of active weekday numbers (1–7) for this schedule.
    var activeDays: Set<Int> {
        switch frequency {
        case .daily: Set(1...7)
        case .weekdays: Set([2, 3, 4, 5, 6]) // Mon–Fri
        case .weekends: Set([1, 7])            // Sun, Sat
        case .weekly: Set([Calendar.current.component(.weekday, from: anchorDate ?? .now)])
        case .monthly, .everyXDays: Set(1...7)
        case .custom: customDays ?? Set(1...7)
        }
    }

    /// Check if this schedule is active on a given date.
    func isActive(on date: Date) -> Bool {
        let calendar = Calendar.current
        switch frequency {
        case .monthly:
            return calendar.component(.day, from: date) == calendar.component(.day, from: anchorDate ?? .now)
        case .everyXDays:
            let start = calendar.startOfDay(for: anchorDate ?? .now)
            let target = calendar.startOfDay(for: date)
            let days = calendar.dateComponents([.day], from: start, to: target).day ?? -1
            return days >= 0 && days % max(1, intervalDays ?? 1) == 0
        default:
            let weekday = calendar.component(.weekday, from: date)
            return activeDays.contains(weekday)
        }
    }
}
