//
//  TaskService.swift
//  What Now?
//

import Foundation
import SwiftData

/// Manages task lifecycle: creation, completion, postponement, and queries.
@Observable
final class TaskService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create

    @discardableResult
    func createTask(
        title: String,
        taskDescription: String = "",
        category: WNCategory? = nil,
        priority: TaskPriority = .medium,
        deadline: Date? = nil,
        estimatedMinutes: Int? = nil,
        preferredTimeOfDay: TimeOfDay? = nil,
        repeatSchedule: RepeatSchedule? = nil,
        notes: String? = nil
    ) -> WNTask {
        let task = WNTask(
            title: title,
            taskDescription: taskDescription,
            category: category,
            priority: priority,
            deadline: deadline,
            estimatedMinutes: estimatedMinutes,
            preferredTimeOfDay: preferredTimeOfDay,
            notes: notes
        )
        task.repeatSchedule = repeatSchedule
        context.insert(task)
        try? context.save()
        return task
    }

    // MARK: - Update

    func save() {
        try? context.save()
    }

    // MARK: - Delete

    func deleteTask(_ task: WNTask) {
        context.delete(task)
        try? context.save()
    }

    // MARK: - Status Transitions

    func startTask(_ task: WNTask) {
        task.statusEnum = .inProgress
        try? context.save()
    }

    func completeTask(_ task: WNTask) {
        task.statusEnum = .completed
        task.completedAt = Date()
        if task.isRecurring {
            task.recurrenceLastCompletedAt = task.completedAt
        }

        let entry = WNHistoryEntry(
            entryType: .taskCompleted,
            task: task,
            durationMinutes: task.estimatedMinutes,
            categoryName: task.category?.name
        )
        context.insert(entry)
        try? context.save()
    }

    func postponeTask(_ task: WNTask) {
        // A postponed task should be offered again as pending, including when it
        // was previously being focused.
        task.statusEnum = .pending
        task.postponementCount += 1

        let entry = WNHistoryEntry(
            entryType: .taskPostponed,
            task: task,
            categoryName: task.category?.name
        )
        context.insert(entry)
        try? context.save()
    }

    func abandonTask(_ task: WNTask) {
        task.statusEnum = .abandoned

        let entry = WNHistoryEntry(
            entryType: .taskAbandoned,
            task: task,
            categoryName: task.category?.name
        )
        context.insert(entry)
        try? context.save()
    }

    // MARK: - Subtasks

    @discardableResult
    func addSubtask(to task: WNTask, title: String, estimatedMinutes: Int? = nil) -> WNSubtask {
        let sortOrder = task.subtasks.count
        let subtask = WNSubtask(
            title: title,
            estimatedMinutes: estimatedMinutes,
            sortOrder: sortOrder,
            parentTask: task
        )
        context.insert(subtask)
        try? context.save()
        return subtask
    }

    func completeSubtask(_ subtask: WNSubtask) {
        subtask.isCompleted = true
        subtask.completedAt = Date()
        try? context.save()
    }

    func deleteSubtask(_ subtask: WNSubtask) {
        context.delete(subtask)
        try? context.save()
    }

    // MARK: - Postponement Intelligence

    /// Whether this task has been postponed enough times to suggest decomposition.
    func shouldSuggestDecomposition(for task: WNTask) -> Bool {
        task.postponementCount >= 3 && task.subtasks.isEmpty
    }

    /// Split a task into subtasks with the given titles and estimates.
    func decomposeTask(_ task: WNTask, steps: [(title: String, minutes: Int?)]) {
        for (index, step) in steps.enumerated() {
            let subtask = WNSubtask(
                title: step.title,
                estimatedMinutes: step.minutes,
                sortOrder: index,
                parentTask: task
            )
            context.insert(subtask)
        }
        try? context.save()
    }

    // MARK: - Queries

    func allTasks() -> [WNTask] {
        let descriptor = FetchDescriptor<WNTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func pendingTasks(for date: Date = .now) -> [WNTask] {
        refreshRecurringTasks(for: date)
        let pending = TaskStatus.pending.rawValue
        let inProgress = TaskStatus.inProgress.rawValue
        let descriptor = FetchDescriptor<WNTask>(
            predicate: #Predicate { $0.status == pending || $0.status == inProgress },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return ((try? context.fetch(descriptor)) ?? []).filter { $0.isScheduled(on: date) }
    }

    /// Advances completed recurring tasks when their next scheduled day arrives.
    /// A single model object represents the repeating task; history preserves each completion.
    func refreshRecurringTasks(for date: Date = .now) {
        let completed = TaskStatus.completed.rawValue
        let descriptor = FetchDescriptor<WNTask>(predicate: #Predicate { $0.status == completed })
        let startOfToday = Calendar.current.startOfDay(for: date)
        var changed = false

        for task in (try? context.fetch(descriptor)) ?? [] {
            guard task.isRecurring,
                  task.isScheduled(on: date),
                  let completedAt = task.completedAt,
                  Calendar.current.startOfDay(for: completedAt) < startOfToday
            else { continue }

            task.statusEnum = .pending
            task.completedAt = nil
            changed = true
        }

        if changed { try? context.save() }
    }

    func completedTasks() -> [WNTask] {
        let completed = TaskStatus.completed.rawValue
        let descriptor = FetchDescriptor<WNTask>(
            predicate: #Predicate { $0.status == completed },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func overdueTasks() -> [WNTask] {
        pendingTasks().filter(\.isOverdue)
    }

    func tasksDueSoon(withinHours hours: Int = 24) -> [WNTask] {
        let cutoff = Date().addingTimeInterval(TimeInterval(hours * 3600))
        return pendingTasks().filter { task in
            guard let deadline = task.deadline else { return false }
            return deadline <= cutoff
        }
    }

    func tasksForCategory(_ category: WNCategory) -> [WNTask] {
        pendingTasks().filter { $0.category?.id == category.id }
    }

    /// Total count of pending tasks.
    var pendingCount: Int {
        let pending = TaskStatus.pending.rawValue
        let inProgress = TaskStatus.inProgress.rawValue
        let descriptor = FetchDescriptor<WNTask>(
            predicate: #Predicate { $0.status == pending || $0.status == inProgress }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }
}
