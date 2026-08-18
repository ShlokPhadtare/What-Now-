//
//  PlanView.swift
//  What Now?
//

import SwiftUI
import SwiftData

/// The Plan tab showing a visual daily timeline.
struct PlanView: View {
    @Environment(\.appState) private var appState
    @State private var selectedDate: Date = .now
    @State private var dailyPlan: WNDailyPlan?

    @Query(
        filter: #Predicate<WNTask> { task in
            task.status == "pending" || task.status == "inProgress"
        },
        sort: \WNTask.createdAt
    ) private var pendingTasks: [WNTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: WNTheme.Spacing.lg) {
                // Native Date Picker Header
                HStack {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()

                    Spacer()

                    if dailyPlan != nil {
                        Button {
                            Task { await replan() }
                        } label: {
                            if isReplanning {
                                ProgressView().controlSize(.small)
                            } else {
                                Text("Replan")
                            }
                        }
                        .font(.subheadline)
                        .disabled(isReplanning)
                    } else if !pendingTasks.isEmpty {
                        Button {
                            generatePlan()
                        } label: {
                            Text("Generate")
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.vertical, WNTheme.Spacing.xs)

            }
            .padding(.horizontal, WNTheme.Spacing.lg)
            .padding(.top, WNTheme.Spacing.sm)
            .padding(.bottom, WNTheme.Spacing.md)

            if let dailyPlan, !dailyPlan.blocks.isEmpty {
                List {
                    Text("TIMELINE")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))

                    ForEach(dailyPlan.sortedBlocks) { block in
                        BlockRow(block: block, appState: appState) {
                            refreshPlan()
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
            } else if pendingTasks.isEmpty {
                ContentUnavailableView(
                    "No Plan Yet",
                    systemImage: "calendar",
                    description: Text("Add tasks to start planning your day.")
                )
                .padding(.top, WNTheme.Spacing.xxl)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: WNTheme.Spacing.md) {
                    Text("Create a realistic timeline from your tasks and routines.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Button("Plan My Day", action: generatePlan)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                }
                .padding(.top, WNTheme.Spacing.md)
                .padding(.horizontal, WNTheme.Spacing.lg)
                Spacer()
            }
        }
        .navigationTitle("Plan")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState?.presentNewTaskEditor()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear(perform: refreshPlan)
        .onChange(of: selectedDate) { _, _ in refreshPlan() }
    }

    @State private var isReplanning: Bool = false

    private func refreshPlan() {
        dailyPlan = appState?.planService.plan(for: selectedDate)
    }

    private func generatePlan() {
        withAnimation {
            dailyPlan = appState?.planService.generatePlan(for: selectedDate)
        }
    }
    
    private func replan() async {
        guard let appState else { return }
        isReplanning = true
        try? await Task.sleep(nanoseconds: 300_000_000) // subtle transition
        withAnimation {
            dailyPlan = appState.planService.replanRemainingDay(for: selectedDate)
            isReplanning = false
        }
    }

    // MARK: - Timeline
    // The timeline is now embedded directly in the body using a List.
}

// MARK: - Block Row

struct BlockRow: View {
    let block: WNScheduleBlock
    let appState: AppState?
    let refreshAction: () -> Void
    
    @State private var showActions = false
    
    var isPast: Bool { block.endTime <= .now }
    var isCurrent: Bool { block.startTime <= .now && block.endTime > .now }
    var isOverdue: Bool {
        isPast && block.linkedTask?.statusEnum == .pending
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: WNTheme.Spacing.md) {
            Text(block.startTime.formatted(date: .omitted, time: .shortened))
                .font(.caption.monospacedDigit())
                .foregroundStyle(isCurrent ? Color.accentColor : .secondary)
                .frame(width: 60, alignment: .leading)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(block.title)
                    .font(isCurrent ? .body.weight(.bold) : .body.weight(.medium))
                    .foregroundStyle(isPast && !isOverdue ? .secondary : .primary)
                    .strikethrough(block.linkedTask?.statusEnum == .completed)
                
                HStack {
                    Text("\(block.durationMinutes.formattedMinutes) · \(block.blockTypeEnum.displayName)")
                    if isOverdue {
                        Text("· Overdue")
                    }
                }
                .font(.caption)
                .foregroundStyle(isOverdue ? .red : .secondary)
            }
            Spacer()
        }
        .padding(.vertical, WNTheme.Spacing.sm)
        .opacity((isPast && !isOverdue) ? 0.6 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            if let task = block.linkedTask,
               task.statusEnum == .pending || task.statusEnum == .inProgress {
                showActions = true
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if let task = block.linkedTask, task.statusEnum != .completed {
                Button {
                    appState?.startFocus(for: task)
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .tint(Color.accentColor)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if let task = block.linkedTask, task.statusEnum != .completed {
                Button {
                    withAnimation {
                        appState?.completeTask(task)
                        refreshAction()
                    }
                } label: {
                    Label("Complete", systemImage: "checkmark")
                }
                .tint(.green)
                
                Button {
                    withAnimation {
                        appState?.postponeTask(task)
                        refreshAction()
                    }
                } label: {
                    Label("Postpone", systemImage: "arrow.right.circle")
                }
                .tint(.orange)
            }
        }
        .confirmationDialog(block.title, isPresented: $showActions, titleVisibility: .visible) {
            if let task = block.linkedTask {
                Button("Start Focus") {
                    appState?.startFocus(for: task)
                }
                Button("Complete") {
                    withAnimation {
                        appState?.completeTask(task)
                        refreshAction()
                    }
                }
                Button("Move to Later Today") {
                    withAnimation {
                        // Move block start to 1 hour from now
                        let newStart = Date.now.addingTimeInterval(.hours(1))
                        let duration = block.durationMinutes
                        block.startTime = newStart
                        block.endTime = newStart.addingTimeInterval(.minutes(duration))
                        appState?.taskService.save()
                        refreshAction()
                    }
                }
                Button("Move to Tomorrow") {
                    withAnimation {
                        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: block.startTime) ?? block.startTime
                        let duration = block.durationMinutes
                        block.startTime = tomorrow
                        block.endTime = tomorrow.addingTimeInterval(.minutes(duration))
                        if let task = block.linkedTask {
                            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)
                            task.deadline = nextDay
                            appState?.taskService.save()
                        }
                        refreshAction()
                    }
                }
                Button("Postpone") {
                    withAnimation {
                        appState?.postponeTask(task)
                        refreshAction()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

// MARK: - Plan Task Row

struct PlanTaskRow: View {
    let task: WNTask
    let accentColor: Color

    var body: some View {
        HStack(spacing: WNTheme.Spacing.md) {
            // Timeline indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: WNTheme.Spacing.xs) {
                Text(task.title)
                    .font(.body.weight(.medium))

                HStack(spacing: WNTheme.Spacing.sm) {
                    if let category = task.category {
                        Text(category.name)
                            .foregroundStyle(.secondary)
                    }

                    if let minutes = task.estimatedMinutes {
                        Text(minutes.formattedMinutes)
                            .foregroundStyle(.secondary)
                    }

                    if let deadline = task.deadline {
                        Text(deadline.relativeDay)
                            .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }
                }
                .font(.caption)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, WNTheme.Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        PlanView()
    }
}
