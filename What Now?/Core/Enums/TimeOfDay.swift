//
//  TimeOfDay.swift
//  What Now?
//

import Foundation

/// Represents a broad time-of-day window for user preferences and scheduling.
enum TimeOfDay: String, Codable, CaseIterable, Identifiable {
    case morning    // roughly 6:00–12:00
    case afternoon  // roughly 12:00–17:00
    case evening    // roughly 17:00–22:00
    case anytime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: "Morning"
        case .afternoon: "Afternoon"
        case .evening: "Evening"
        case .anytime: "Anytime"
        }
    }

    var symbolName: String {
        switch self {
        case .morning: "sunrise"
        case .afternoon: "sun.max"
        case .evening: "moon.stars"
        case .anytime: "clock"
        }
    }

    /// Hour range (start inclusive, end exclusive) for scheduling purposes.
    var hourRange: ClosedRange<Int> {
        switch self {
        case .morning: 6...11
        case .afternoon: 12...16
        case .evening: 17...21
        case .anytime: 6...21
        }
    }

    /// Determine the current time-of-day from a `Date`.
    static func current(from date: Date = .now) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .evening // late night treated as evening
        }
    }
}
