//
//  WNFocusSession.swift
//  What Now?
//

import Foundation
import SwiftData

/// A timed focus session, optionally linked to a task.
@Model
final class WNFocusSession {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var plannedMinutes: Int = 25
    var actualMinutes: Int?
    var endedAt: Date?
    var wasCompleted: Bool = false
    var wasAbandoned: Bool = false
    var categoryName: String?

    var task: WNTask?

    // MARK: - Computed Properties

    /// Whether the session is currently active (started but not ended).
    var isActive: Bool {
        endedAt == nil
    }

    /// The planned end time based on startedAt + plannedMinutes.
    var plannedEndTime: Date {
        startedAt.addingTimeInterval(TimeInterval(plannedMinutes * 60))
    }

    /// Elapsed minutes since the session started (clamped to actual if ended).
    var elapsedMinutes: Int {
        if let actualMinutes {
            return actualMinutes
        }
        let elapsed = Date().timeIntervalSince(startedAt) / 60
        return min(Int(elapsed), plannedMinutes)
    }

    /// Remaining minutes in the session.
    var remainingMinutes: Int {
        max(0, plannedMinutes - elapsedMinutes)
    }

    // MARK: - Init

    init(
        task: WNTask? = nil,
        plannedMinutes: Int = 25,
        categoryName: String? = nil
    ) {
        self.id = UUID()
        self.startedAt = Date()
        self.plannedMinutes = plannedMinutes
        self.task = task
        self.categoryName = categoryName ?? task?.category?.name
    }
}
