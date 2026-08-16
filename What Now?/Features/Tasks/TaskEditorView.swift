//
//  TaskEditorView.swift
//  What Now?
//

import SwiftUI
import SwiftData

/// An effortless, native task entry and edit screen.
struct TaskEditorView: View {
    @Environment(\.appState) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: WNTask?

    @State private var title: String = ""
    @State private var selectedDay: QuickDay = .today
    @State private var description: String = ""
    @State private var selectedCategory: WNCategory?
    @State private var priority: TaskPriority = .medium
    @State private var estimatedMinutes: Int = 30
    @State private var categories: [WNCategory] = []

    @FocusState private var isTitleFocused: Bool

    private var isEditing: Bool { task != nil }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    enum QuickDay: String, CaseIterable, Identifiable {
        case today = "Today"
        case tomorrow = "Tomorrow"
        case later = "Later"
        case noDate = "No date"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Main task input
                Section {
                    TextField("What do you want to do?", text: $title, axis: .vertical)
                        .font(.body)
                        .focused($isTitleFocused)
                        .lineLimit(1...3)
                }

                // Quick Day selection
                Section("When") {
                    Picker("Schedule", selection: $selectedDay) {
                        ForEach(QuickDay.allCases) { day in
                            Text(day.rawValue).tag(day)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Details & Properties
                Section("Details") {
                    Stepper("Duration: \(estimatedMinutes.formattedMinutes)", value: $estimatedMinutes, in: 5...480, step: 5)

                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }

                    if !categories.isEmpty {
                        Picker("Category", selection: $selectedCategory) {
                            Text("None").tag(nil as WNCategory?)
                            ForEach(categories) { cat in
                                Text(cat.name).tag(cat as WNCategory?)
                            }
                        }
                    }
                }

                // Notes / Description
                Section("Notes") {
                    TextField("Add details...", text: $description, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveTask()
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadState()
                if !isEditing {
                    isTitleFocused = true
                }
            }
        }
    }

    // MARK: - Load / Save

    private func loadState() {
        categories = appState?.categoryService.allCategories() ?? []

        if let task {
            title = task.title
            description = task.taskDescription
            selectedCategory = task.category
            priority = task.priorityEnum
            estimatedMinutes = task.estimatedMinutes ?? 30

            if let deadline = task.deadline {
                if deadline.isToday { selectedDay = .today }
                else if deadline.isTomorrow { selectedDay = .tomorrow }
                else { selectedDay = .later }
            } else {
                selectedDay = .noDate
            }
        }
    }

    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        var targetDeadline: Date?
        let now = Date.now
        switch selectedDay {
        case .today:
            targetDeadline = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)
        case .tomorrow:
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
            targetDeadline = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: tomorrow)
        case .later:
            let later = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
            targetDeadline = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: later)
        case .noDate:
            targetDeadline = nil
        }

        if let task {
            task.title = trimmedTitle
            task.taskDescription = description
            task.category = selectedCategory
            task.priorityEnum = priority
            task.deadline = targetDeadline
            task.estimatedMinutes = estimatedMinutes
            appState?.taskService.save()
        } else {
            appState?.taskService.createTask(
                title: trimmedTitle,
                taskDescription: description,
                category: selectedCategory,
                priority: priority,
                deadline: targetDeadline,
                estimatedMinutes: estimatedMinutes,
                preferredTimeOfDay: nil,
                notes: nil
            )
        }
    }
}
