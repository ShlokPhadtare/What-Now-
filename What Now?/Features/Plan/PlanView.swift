//
//  PlanView.swift
//  What Now?
//

import SwiftUI
import SwiftData

/// The Plan tab showing a visual, schematic daily timeline in native Apple style.
struct PlanView: View {
    @Environment(\.appState) private var appState
    @State private var selectedDate: Date = .now
    @State private var dailyPlan: WNDailyPlan?
    @State private var isReplanning: Bool = false

    @Query(
        filter: #Predicate<WNTask> { task in
            task.status == "pending" || task.status == "inProgress"
        },
        sort: \WNTask.createdAt
    ) private var pendingTasks: [WNTask]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WNTheme.Spacing.lg) {
                // Schematic Date Navigator & Action Controls
                dateNavigatorSection

                if let dailyPlan, !dailyPlan.blocks.isEmpty {
                    // Schematic Day Analytics & Segmented Distribution Bar
                    daySummaryCard(dailyPlan: dailyPlan)

                    // Vertical Timeline
                    timelineSection(dailyPlan: dailyPlan)
                } else if pendingTasks.isEmpty {
                    emptyNoTasksState
                } else {
                    emptyNoPlanState
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, WNTheme.Spacing.xs)
            .padding(.bottom, WNTheme.Spacing.xxl)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Daily Plan")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.shared.playSelection()
                    appState?.presentNewTaskEditor()
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("New Task")
            }
        }
        .onAppear(perform: refreshPlan)
        .onChange(of: selectedDate) { _, _ in refreshPlan() }
    }

    // MARK: - Date Navigator Section

    @ViewBuilder
    private var dateNavigatorSection: some View {
        VStack(spacing: WNTheme.Spacing.sm) {
            HStack(spacing: WNTheme.Spacing.sm) {
                // Previous Day
                Button {
                    HapticManager.shared.playSelection()
                    withAnimation {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: Circle())
                }

                // Native Date Picker with Custom Button Label
                ZStack {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)

                        Text(selectedDateFormatted)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5)
                    )

                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .blendMode(.destinationOver)
                    .opacity(0.015)
                }

                // Next Day
                Button {
                    HapticManager.shared.playSelection()
                    withAnimation {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: Circle())
                }

                Spacer()

                // Today Quick Jump Button
                if !Calendar.current.isDateInToday(selectedDate) {
                    Button {
                        HapticManager.shared.playSelection()
                        withAnimation {
                            selectedDate = .now
                        }
                    } label: {
                        Text("Today")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                }

                // Replan or Generate Action Button
                if dailyPlan != nil {
                    Button {
                        HapticManager.shared.playSoft()
                        Task { await replan() }
                    } label: {
                        if isReplanning {
                            ProgressView()
                                .controlSize(.small)
                                .frame(height: 20)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption2.weight(.bold))
                                Text("Replan")
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5)
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isReplanning)
                } else if !pendingTasks.isEmpty {
                    Button {
                        HapticManager.shared.playSoft()
                        generatePlan()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2.weight(.bold))
                            Text("Generate")
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.accentColor, in: Capsule())
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, WNTheme.Spacing.xs)
    }

    private var selectedDateFormatted: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today, " + selectedDate.formatted(.dateTime.month(.abbreviated).day())
        } else if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow, " + selectedDate.formatted(.dateTime.month(.abbreviated).day())
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday, " + selectedDate.formatted(.dateTime.month(.abbreviated).day())
        } else {
            return selectedDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        }
    }

    // MARK: - Day Summary & Distribution Bar

    @ViewBuilder
    private func daySummaryCard(dailyPlan: WNDailyPlan) -> some View {
        let totalScheduled = dailyPlan.totalScheduledMinutes
        let totalFree = dailyPlan.totalFreeMinutes
        let totalMinutes = max(1, totalScheduled + totalFree)

        let taskMinutes = dailyPlan.blocks
            .filter { $0.blockTypeEnum == .task }
            .reduce(0) { $0 + $1.durationMinutes }
        let routineMinutes = dailyPlan.blocks
            .filter { $0.blockTypeEnum == .routine }
            .reduce(0) { $0 + $1.durationMinutes }
        let breakMinutes = dailyPlan.blocks
            .filter { $0.blockTypeEnum == .breakTime }
            .reduce(0) { $0 + $1.durationMinutes }

        VStack(alignment: .leading, spacing: WNTheme.Spacing.md) {
            // Metrics Row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.accentColor)
                        Text("SCHEDULED")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                    }

                    Text(totalScheduled.formattedMinutes)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(Color.orange)
                        Text("FREE BUFFER")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                    }

                    Text(totalFree.formattedMinutes)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.purple)
                        Text("BLOCKS")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                    }

                    Text("\(dailyPlan.blocks.count)")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                }
            }

            // Visual Proportion Bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    if taskMinutes > 0 {
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: max(4, geo.size.width * CGFloat(taskMinutes) / CGFloat(totalMinutes)))
                    }
                    if routineMinutes > 0 {
                        Capsule()
                            .fill(Color.purple)
                            .frame(width: max(4, geo.size.width * CGFloat(routineMinutes) / CGFloat(totalMinutes)))
                    }
                    if breakMinutes > 0 {
                        Capsule()
                            .fill(Color.orange)
                            .frame(width: max(4, geo.size.width * CGFloat(breakMinutes) / CGFloat(totalMinutes)))
                    }
                    if totalFree > 0 {
                        Capsule()
                            .fill(Color(uiColor: .tertiarySystemFill))
                            .frame(width: max(4, geo.size.width * CGFloat(totalFree) / CGFloat(totalMinutes)))
                    }
                }
            }
            .frame(height: 8)

            // Legend
            HStack(spacing: WNTheme.Spacing.md) {
                if taskMinutes > 0 {
                    HStack(spacing: 4) {
                        Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                        Text("Focus").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                if routineMinutes > 0 {
                    HStack(spacing: 4) {
                        Circle().fill(Color.purple).frame(width: 6, height: 6)
                        Text("Routines").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                if breakMinutes > 0 {
                    HStack(spacing: 4) {
                        Circle().fill(Color.orange).frame(width: 6, height: 6)
                        Text("Breaks").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                if totalFree > 0 {
                    HStack(spacing: 4) {
                        Circle().fill(Color(uiColor: .tertiaryLabel)).frame(width: 6, height: 6)
                        Text("Free").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .wnSchematicCard(padding: WNTheme.Spacing.md, cornerRadius: 16)
    }

    // MARK: - Timeline Section

    @ViewBuilder
    private func timelineSection(dailyPlan: WNDailyPlan) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TIMELINE")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .padding(.horizontal, 4)
                .padding(.bottom, WNTheme.Spacing.sm)

            let sorted = dailyPlan.sortedBlocks
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, block in
                let isLast = index == sorted.count - 1
                SchematicBlockRow(
                    block: block,
                    isLast: isLast,
                    appState: appState,
                    refreshAction: refreshPlan
                )
            }
        }
    }

    // MARK: - Empty States

    @ViewBuilder
    private var emptyNoTasksState: some View {
        VStack(spacing: WNTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.top, WNTheme.Spacing.xxl)

            VStack(spacing: 6) {
                Text("No Tasks to Plan")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Add tasks to your inbox to generate an intelligent, time-blocked schedule.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                HapticManager.shared.playSelection()
                appState?.presentNewTaskEditor()
            } label: {
                Label("Add First Task", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, WNTheme.Spacing.xl)
    }

    @ViewBuilder
    private var emptyNoPlanState: some View {
        VStack(spacing: WNTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.purple)
            }
            .padding(.top, WNTheme.Spacing.xl)

            VStack(spacing: 6) {
                Text("Ready to Plan Your Day")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Turn your \(pendingTasks.count) pending tasks and routines into a structured, realistic timeline.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button(action: generatePlan) {
                HapticManager.shared.playSuccess()
                return Label("Generate Today's Plan", systemImage: "sparkles")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .wnSchematicCard(padding: WNTheme.Spacing.xl, cornerRadius: 20)
        .padding(.top, WNTheme.Spacing.md)
    }

    // MARK: - Actions

    private func refreshPlan() {
        dailyPlan = appState?.planService.plan(for: selectedDate)
    }

    private func generatePlan() {
        withAnimation {
            HapticManager.shared.playSuccess()
            dailyPlan = appState?.planService.generatePlan(for: selectedDate)
        }
    }

    private func replan() async {
        guard let appState else { return }
        isReplanning = true
        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation {
            dailyPlan = appState.planService.replanRemainingDay(for: selectedDate)
            isReplanning = false
        }
    }
}

// MARK: - Schematic Block Row

struct SchematicBlockRow: View {
    let block: WNScheduleBlock
    let isLast: Bool
    let appState: AppState?
    let refreshAction: () -> Void

    @State private var showActions = false

    var isPast: Bool { block.endTime <= .now }
    var isCurrent: Bool { block.startTime <= .now && block.endTime > .now }
    var isOverdue: Bool {
        isPast && block.linkedTask?.statusEnum == .pending
    }
    var isCompleted: Bool {
        block.isCompleted || block.linkedTask?.statusEnum == .completed
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time Column
            VStack(alignment: .trailing, spacing: 2) {
                Text(block.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption.weight(isCurrent ? .bold : .medium).monospacedDigit())
                    .foregroundStyle(isCurrent ? Color.accentColor : .primary)

                Text(block.endTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)

                Text(block.durationMinutes.formattedMinutes)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
            .frame(width: 58, alignment: .trailing)
            .padding(.top, 2)

            // Timeline Spine Column
            VStack(spacing: 0) {
                // Node
                timelineNode
                    .padding(.top, 2)

                // Vertical Connector Line
                if !isLast {
                    Rectangle()
                        .fill(isPast ? Color(uiColor: .separator).opacity(0.3) : Color.accentColor.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 2)
                }
            }
            .frame(width: 20)

            // Schematic Block Card
            blockCard
                .padding(.bottom, isLast ? 4 : 12)
        }
    }

    // MARK: - Timeline Node

    @ViewBuilder
    private var timelineNode: some View {
        if isCurrent {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.25))
                    .frame(width: 18, height: 18)

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 10, height: 10)
            }
        } else if isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color.green)
        } else if isOverdue {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color.red)
        } else {
            Circle()
                .strokeBorder(typeColor.opacity(0.6), lineWidth: 2)
                .background(Circle().fill(Color(uiColor: .systemBackground)))
                .frame(width: 12, height: 12)
        }
    }

    private var typeColor: Color {
        switch block.blockTypeEnum {
        case .task: return Color.accentColor
        case .routine: return Color.purple
        case .calendarEvent: return Color.teal
        case .breakTime: return Color.orange
        case .freeTime: return Color.secondary
        }
    }

    // MARK: - Block Card

    @ViewBuilder
    private var blockCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Type badge & Category badge
            HStack(spacing: 6) {
                Label(block.blockTypeEnum.displayName, systemImage: block.blockTypeEnum.symbolName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(typeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(typeColor.opacity(0.12), in: Capsule())

                if let category = block.linkedTask?.category {
                    HStack(spacing: 4) {
                        Circle().fill(category.color).frame(width: 5, height: 5)
                        Text(category.name)
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(category.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(category.color.opacity(0.1), in: Capsule())
                }

                if isOverdue {
                    Text("Overdue")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.12), in: Capsule())
                }

                Spacer()

                if let task = block.linkedTask, task.statusEnum != .completed {
                    Button {
                        HapticManager.shared.playSoft()
                        appState?.startFocus(for: task)
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Title
            Text(block.title)
                .font(.subheadline.weight(isCurrent ? .bold : .semibold))
                .foregroundStyle(isPast && !isOverdue ? .secondary : .primary)
                .strikethrough(isCompleted)

            // Subtask count or notes if available
            if let task = block.linkedTask, !task.subtasks.isEmpty {
                let progress = task.subtaskProgress
                HStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .font(.caption2)
                    Text("\(progress.completed) of \(progress.total) subtasks")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(WNTheme.Spacing.md)
        .background(
            isCurrent
                ? Color.accentColor.opacity(0.06)
                : Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isCurrent ? Color.accentColor.opacity(0.4) : Color(uiColor: .separator).opacity(0.2),
                    lineWidth: isCurrent ? 1 : 0.5
                )
        )
        .opacity((isPast && !isOverdue) ? 0.65 : 1.0)
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
                    HapticManager.shared.playSoft()
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
                        HapticManager.shared.playSuccess()
                        appState?.completeTask(task)
                        refreshAction()
                    }
                } label: {
                    Label("Complete", systemImage: "checkmark")
                }
                .tint(.green)

                Button {
                    withAnimation {
                        HapticManager.shared.playRigid()
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
                        HapticManager.shared.playSuccess()
                        appState?.completeTask(task)
                        refreshAction()
                    }
                }
                Button("Move to Later Today (+1h)") {
                    withAnimation {
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
                        HapticManager.shared.playRigid()
                        appState?.postponeTask(task)
                        refreshAction()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    NavigationStack {
        PlanView()
    }
}
