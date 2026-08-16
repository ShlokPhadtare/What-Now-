//
//  WNRoutine.swift
//  What Now?
//

import Foundation
import SwiftData

/// A recurring routine (morning routine, gym, etc.) that appears in daily plans.
@Model
final class WNRoutine {
    var id: UUID = UUID()
    var name: String = ""
    var estimatedMinutes: Int = 30
    var preferredHour: Int = 8
    var preferredMinute: Int = 0
    var activeDaysRaw: String = "2,3,4,5,6"
    var isActive: Bool = true

    var category: WNCategory?

    // MARK: - Computed Properties

    /// The set of weekday numbers (1=Sunday, 7=Saturday) this routine is active.
    var activeDays: Set<Int> {
        get { Set(activeDaysRaw.split(separator: ",").compactMap { Int($0) }) }
        set { activeDaysRaw = newValue.sorted().map(String.init).joined(separator: ",") }
    }

    /// Whether this routine is active on a given date.
    func isActive(on date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return isActive && activeDays.contains(weekday)
    }

    /// The preferred start time as `DateComponents`.
    var preferredTimeComponents: DateComponents {
        DateComponents(hour: preferredHour, minute: preferredMinute)
    }

    // MARK: - Init

    init(
        name: String,
        estimatedMinutes: Int = 30,
        preferredHour: Int = 8,
        preferredMinute: Int = 0,
        activeDays: Set<Int> = Set([2, 3, 4, 5, 6]),
        category: WNCategory? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.estimatedMinutes = estimatedMinutes
        self.preferredHour = preferredHour
        self.preferredMinute = preferredMinute
        self.activeDaysRaw = activeDays.sorted().map(String.init).joined(separator: ",")
        self.category = category
    }
}
