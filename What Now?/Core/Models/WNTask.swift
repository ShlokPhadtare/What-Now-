//
//  WNTask.swift
//  What Now?
//

import Foundation
import SwiftData

/// The primary task model. Prefixed `WN` to avoid conflict with `Swift.Task`.
///
/// Enums are stored as `String` raw values for SwiftData compatibility.
/// Use the computed `*Enum` properties for type-safe access.
@Model
final class WNTask {
    var id: UUID = UUID()
    var title: String = ""
    var taskDescription: String = ""
    var priority: String = TaskPriority.medium.rawValue
    var deadline: Date?
    var estimatedMinutes: Int?
    var preferredTimeOfDay: String?
    var repeatScheduleData: Data?
    /// Last completed occurrence. Recurring tasks are reset only on their next due date.
    var recurrenceLastCompletedAt: Date?
    var status: String = TaskStatus.pending.rawValue
    var notes: String?
    var createdAt: Date = Date()
    var completedAt: Date?
    var postponementCount: Int = 0
    var sortOrder: Int = 0

    // MARK: - Relationships

    var category: WNCategory?

    @Relationship(deleteRule: .cascade, inverse: \WNSubtask.parentTask)
    var subtasks: [WNSubtask] = []

    @Relationship(deleteRule: .nullify, inverse: \WNFocusSession.task)
    var focusSessions: [WNFocusSession] = []

    @Relationship(deleteRule: .cascade, inverse: \WNHistoryEntry.task)
    var historyEntries: [WNHistoryEntry] = []

    @Relationship(deleteRule: .nullify, inverse: \WNScheduleBlock.linkedTask)
    var scheduleBlocks: [WNScheduleBlock] = []

    // MARK: - Computed Properties

    var priorityEnum: TaskPriority {
        get { TaskPriority(rawValue: priority) ?? .medium }
        set { priority = newValue.rawValue }
    }

    var statusEnum: TaskStatus {
        get { TaskStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }

    var preferredTimeEnum: TimeOfDay? {
        get { preferredTimeOfDay.flatMap { TimeOfDay(rawValue: $0) } }
        set { preferredTimeOfDay = newValue?.rawValue }
    }

    var repeatSchedule: RepeatSchedule? {
        get {
            guard let data = repeatScheduleData else { return nil }
            return try? JSONDecoder().decode(RepeatSchedule.self, from: data)
        }
        set {
            repeatScheduleData = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }

    var isRecurring: Bool { repeatSchedule != nil }

    func isScheduled(on date: Date) -> Bool {
        repeatSchedule?.isActive(on: date) ?? true
    }

    var isOverdue: Bool {
        guard let deadline else { return false }
        return deadline < Date() && statusEnum != .completed && statusEnum != .abandoned
    }

    var isActive: Bool {
        statusEnum.isActive
    }

    /// Effective estimated minutes, defaulting to 15 if not set.
    var effectiveEstimatedMinutes: Int {
        estimatedMinutes ?? 15
    }

    /// Completed subtask count / total subtask count.
    var subtaskProgress: (completed: Int, total: Int) {
        let total = subtasks.count
        let completed = subtasks.filter(\.isCompleted).count
        return (completed, total)
    }

    // MARK: - Init

    init(
        title: String,
        taskDescription: String = "",
        category: WNCategory? = nil,
        priority: TaskPriority = .medium,
        deadline: Date? = nil,
        estimatedMinutes: Int? = nil,
        preferredTimeOfDay: TimeOfDay? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.category = category
        self.priority = priority.rawValue
        self.deadline = deadline
        self.estimatedMinutes = estimatedMinutes
        self.preferredTimeOfDay = preferredTimeOfDay?.rawValue
        self.notes = notes
        self.createdAt = Date()
    }
}
