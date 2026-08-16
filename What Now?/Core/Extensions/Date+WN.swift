//
//  Date+WN.swift
//  What Now?
//

import Foundation

extension Date {

    /// The start of the calendar day (midnight) for this date.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// The end of the calendar day (23:59:59) for this date.
    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
    }

    /// Whether this date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Whether this date is tomorrow.
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Whether this date is within the current calendar week.
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: .now, toGranularity: .weekOfYear)
    }

    /// Minutes from now (negative if in the past).
    var minutesFromNow: Int {
        Int(timeIntervalSinceNow / 60)
    }

    /// Hours from now (negative if in the past).
    var hoursFromNow: Double {
        timeIntervalSinceNow / 3600
    }

    /// A date with the given hour and minute on the same calendar day.
    func atTime(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: self)!
    }

    /// Add a number of minutes to this date.
    func addingMinutes(_ minutes: Int) -> Date {
        addingTimeInterval(TimeInterval(minutes * 60))
    }

    /// Time-of-day greeting string.
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: self)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    /// Relative description ("Today", "Tomorrow", "Wednesday", or formatted date).
    var relativeDay: String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        if isThisWeek {
            return formatted(.dateTime.weekday(.wide))
        }
        return formatted(.dateTime.month(.abbreviated).day())
    }

    /// Short time string (e.g., "9:30 AM").
    var shortTime: String {
        formatted(date: .omitted, time: .shortened)
    }
}
