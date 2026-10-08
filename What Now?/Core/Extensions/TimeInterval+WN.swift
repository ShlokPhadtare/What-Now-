//
//  TimeInterval+WN.swift
//  What Now?
//

import Foundation

extension TimeInterval {

    /// Convert a TimeInterval (seconds) to a human-readable duration string.
    ///
    /// Examples:
    /// - 5400 → "1h 30m"
    /// - 900 → "15m"
    /// - 7200 → "2h"
    var formattedDuration: String {
        let totalMinutes = Int(self / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    /// Convert a TimeInterval (seconds) to total minutes.
    var totalMinutes: Int {
        Int(self / 60)
    }

    /// Create a TimeInterval from minutes.
    static func minutes(_ minutes: Int) -> TimeInterval {
        TimeInterval(minutes * 60)
    }

    /// Create a TimeInterval from hours.
    static func hours(_ hours: Int) -> TimeInterval {
        TimeInterval(hours * 3600)
    }

    /// Formats a countdown duration as mm:ss or h:mm:ss for timer displays.
    var formattedTimerCountdown: String {
        let total = max(0, Int(self))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

extension Int {
    /// Format minutes as a human-readable duration string.
    ///
    /// Examples:
    /// - 90 → "1h 30m"
    /// - 15 → "15 min"
    /// - 120 → "2h"
    var formattedMinutes: String {
        let hours = self / 60
        let mins = self % 60

        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(self) min"
        }
    }
}
