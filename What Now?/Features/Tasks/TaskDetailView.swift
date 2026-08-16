//
//  TaskDetailView.swift
//  What Now?
//

import SwiftUI
import SwiftData

/// Detail view for a single task showing metadata, subtasks, and actions.
struct TaskDetailView: View {
    @Environment(\.appState) private var appState
    @Bindable var task: WNTask

    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            // MARK: - Properties
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(task.statusEnum.displayName)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Priority")
                    Spacer()
                    Text(task.priorityEnum.displayName)
                        .foregroundStyle(.secondary)
                }

                if let category = task.category {
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(category.name)
                            .foregroundStyle(.secondary)
                    }
                }

                if let minutes = task.estimatedMinutes {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(minutes.formattedMinutes)
                            .foregroundStyle(.secondary)
                    }
                }

                if let deadline = task.deadline {
                    HStack {
                        Text("Deadline")
                        Spacer()
                        Text(deadline.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }
                }
            }

            // MARK: - Subtasks
            if !task.subtasks.isEmpty {
                Section("Subtasks") {
                    let sorted = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }
                    ForEach(sorted) { subtask in
                        HStack(spacing: WNTheme.Spacing.md) {
                            Button {
                                withAnimation {
                                    if subtask.isCompleted {
                                        subtask.isCompleted = false
                                        subtask.completedAt = nil
                                    } else {
                                        appState?.taskService.completeSubtask(subtask)
                                    }
                                }
                            } label: {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                            }
                            .buttonStyle(.plain)

                            Text(subtask.title)
                                .strikethrough(subtask.isCompleted)
                                .foregroundStyle(subtask.isCompleted ? .secondary : .primary)

                            Spacer()

                            if let minutes = subtask.estimatedMinutes {
                                Text(minutes.formattedMinutes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // MARK: - Notes / Description
            if !task.taskDescription.isEmpty {
                Section("Notes") {
                    Text(task.taskDescription)
                        .font(.body)
                }
            }

            // MARK: - Actions
            if task.isActive {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Task")
                    }
                }
            }
        }
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if task.isActive {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        appState?.presentTaskEditor(for: task)
                    }
                }
            }
        }
        .confirmationDialog("Delete this task?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                appState?.taskService.deleteTask(task)
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
