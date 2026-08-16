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
        ScrollView {
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
                    }
                }
                .padding(.vertical, WNTheme.Spacing.xs)

                if let dailyPlan, !dailyPlan.blocks.isEmpty {
                    timeline(for: dailyPlan)
                } else if pendingTasks.isEmpty {
                    ContentUnavailableView(
                        "No Plan Yet",
                        systemImage: "calendar",
                        description: Text("Add tasks to start planning your day.")
                    )
                    .padding(.top, WNTheme.Spacing.xxl)
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
                }
            }
            .padding(.horizontal, WNTheme.Spacing.lg)
            .padding(.top, WNTheme.Spacing.sm)
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

    @ViewBuilder
    private func timeline(for plan: WNDailyPlan) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.md) {
            Text("TIMELINE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(plan.sortedBlocks) { block in
                    BlockRow(block: block, appState: appState) {
                        refreshPlan()
                    }

                    if block.id != plan.sortedBlocks.last?.id {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
        }
    }
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
            if let task = block.linkedTask, task.statusEnum == .pending {
                showActions = true
            }
        }
        .confirmationDialog(block.title, isPresented: $showActions, titleVisibility: .visible) {
            if let task = block.linkedTask {
                Button("Start Focus") {
                    appState?.startFocus(for: task)
                    appState?.selectedTab = .focus
                }
                Button("Complete") {
                    withAnimation {
                        appState?.completeTask(task)
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
