//
//  TaskListView.swift
//  What Now?
//

import SwiftUI
import SwiftData

/// The main task management screen showing all pending tasks with swipe actions.
struct TaskListView: View {
    @Environment(\.appState) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<WNTask> { task in
            task.status == "pending" || task.status == "inProgress"
        },
        sort: \WNTask.createdAt,
        order: .reverse
    ) private var pendingTasks: [WNTask]

    @Query(
        filter: #Predicate<WNTask> { task in
            task.status == "completed"
        },
        sort: \WNTask.completedAt,
        order: .reverse
    ) private var completedTasks: [WNTask]

    @State private var showCompleted = false
    @State private var searchText = ""
    @State private var filterPriority: TaskPriority?

    var body: some View {
        Group {
            if pendingTasks.isEmpty && completedTasks.isEmpty {
                WNEmptyState(
                    symbol: "checklist",
                    title: "No Tasks Yet",
                    message: "Create your first task to get started.",
                    actionTitle: "Create Task"
                ) {
                    appState?.presentNewTaskEditor()
                }
            } else {
                taskList
            }
        }
        .navigationTitle("Tasks")
        .searchable(text: $searchText, prompt: "Search tasks")
        .onAppear {
            appState?.taskService.refreshRecurringTasks()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState?.presentNewTaskEditor()
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        filterPriority = nil
                    } label: {
                        Label("All Priorities", systemImage: "line.3.horizontal.decrease.circle")
                    }

                    ForEach(TaskPriority.allCases) { priority in
                        Button {
                            filterPriority = priority
                        } label: {
                            Label(priority.displayName, systemImage: priority.symbolName)
                        }
                    }
                } label: {
                    Image(systemName: filterPriority == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }
        }
    }

    // MARK: - Task List

    @ViewBuilder
    private var taskList: some View {
        List {
            // Pending section
            if !filteredPendingTasks.isEmpty {
                Section {
                    ForEach(filteredPendingTasks) { task in
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            TaskRowView(task: task)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                withAnimation {
                                    appState?.completeTask(task)
                                }
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                withAnimation {
                                    appState?.postponeTask(task)
                                }
                            } label: {
                                Label("Postpone", systemImage: "arrow.uturn.right")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    Text("Pending · \(filteredPendingTasks.count)")
                }
            }

            // Completed section (collapsible)
            if !completedTasks.isEmpty {
                Section {
                    ForEach(filteredCompletedTasks) { task in
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            TaskRowView(task: task)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    appState?.taskService.deleteTask(task)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Completed · \(filteredCompletedTasks.count)")
                }
            }
        }
        .listStyle(.plain)
        .animation(.default, value: pendingTasks.count)
    }

    // MARK: - Filtered Data

    private var filteredPendingTasks: [WNTask] {
        pendingTasks
            .filter { $0.isScheduled(on: .now) }
            .filtered(by: searchText, priority: filterPriority)
    }

    private var filteredCompletedTasks: [WNTask] {
        completedTasks.filtered(by: searchText, priority: filterPriority)
    }
}

// MARK: - Filtering Extension

private extension [WNTask] {
    func filtered(by search: String, priority: TaskPriority?) -> [WNTask] {
        var result = self

        if !search.isEmpty {
            let lowered = search.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(lowered) ||
                $0.taskDescription.lowercased().contains(lowered) ||
                $0.category?.name.lowercased().contains(lowered) == true
            }
        }

        if let priority {
            result = result.filter { $0.priorityEnum == priority }
        }

        return result
    }
}

// MARK: - Task Row

struct TaskRowView: View {
    let task: WNTask

    var body: some View {
        HStack(spacing: WNTheme.Spacing.md) {
            // Minimal status indicator
            Image(systemName: task.statusEnum == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.statusEnum == .completed ? .secondary : .primary)
                .font(.title3)

            VStack(alignment: .leading, spacing: WNTheme.Spacing.xs) {
                Text(task.title)
                    .font(.body.weight(.medium))
                    .strikethrough(task.statusEnum == .completed)
                    .foregroundStyle(task.statusEnum == .completed ? .secondary : .primary)

                HStack(spacing: WNTheme.Spacing.sm) {
                    if let category = task.category {
                        Text(category.name)
                    }

                    if let minutes = task.estimatedMinutes {
                        Text(minutes.formattedMinutes)
                    }

                    if let deadline = task.deadline {
                        Text(deadline.relativeDay)
                            .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }

                    if task.postponementCount > 0 {
                        Text("↻\(task.postponementCount)")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Subtask progress
            if !task.subtasks.isEmpty {
                let progress = task.subtaskProgress
                Text("\(progress.completed)/\(progress.total)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, WNTheme.Spacing.xs)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        TaskListView()
    }
}
