//
//  FocusService.swift
//  What Now?
//

import Foundation
import SwiftData

/// Owns the persisted lifecycle and live countdown for the single active focus session.
@Observable
@MainActor
final class FocusService: NSObject {
    private let context: ModelContext
    private var timer: Timer?

    var activeSession: WNFocusSession?
    private(set) var currentDate = Date()

    init(context: ModelContext) {
        self.context = context
        super.init()
        restoreActiveSession()
    }

    var remainingTime: TimeInterval {
        guard let activeSession else { return 0 }
        return max(0, activeSession.plannedEndTime.timeIntervalSince(currentDate))
    }

    @discardableResult
    func startSession(for task: WNTask) -> WNFocusSession {
        if let activeSession {
            return activeSession
        }

        let session = WNFocusSession(
            task: task,
            plannedMinutes: task.effectiveEstimatedMinutes
        )
        context.insert(session)
        activeSession = session
        currentDate = Date()
        save()
        startTimer()
        NotificationManager.shared.scheduleFocusCompletion(taskTitle: task.title, in: TimeInterval(session.plannedMinutes * 60))
        return session
    }

    func endSession(completed: Bool) {
        guard let session = activeSession else { return }

        let endedAt = Date()
        session.endedAt = endedAt
        session.actualMinutes = max(0, Int(endedAt.timeIntervalSince(session.startedAt) / 60))
        session.wasCompleted = completed
        session.wasAbandoned = !completed

        context.insert(WNHistoryEntry(
            entryType: completed ? .focusCompleted : .focusAbandoned,
            task: session.task,
            durationMinutes: session.actualMinutes,
            categoryName: session.categoryName
        ))

        activeSession = nil
        currentDate = endedAt
        timer?.invalidate()
        timer = nil
        NotificationManager.shared.cancelFocusCompletion()
        save()
    }

    private func restoreActiveSession() {
        let descriptor = FetchDescriptor<WNFocusSession>(
            predicate: #Predicate { $0.endedAt == nil },
            sortBy: [SortDescriptor(\WNFocusSession.startedAt, order: .reverse)]
        )
        activeSession = try? context.fetch(descriptor).first
        if activeSession != nil {
            startTimer()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(updateCurrentDate),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func updateCurrentDate() {
        currentDate = Date()
    }

    private func save() {
        try? context.save()
    }
}
