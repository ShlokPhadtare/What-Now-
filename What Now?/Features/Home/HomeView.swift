//
//  HomeView.swift
//  What Now?
//

import SwiftUI
import SwiftData

/// The primary Home / Dashboard screen designed in Apple's schematic, polished style.
struct HomeView: View {
    @Environment(\.appState) private var appState
    @State private var viewModel: HomeViewModel?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: WNTheme.Spacing.lg) {
                // Header context subtitle
                headerSection

                // Active Live Focus Card (if in progress)
                if let session = currentActiveSession {
                    activeFocusCard(session: session)
                }

                // 3-Tile Schematic Glance Strip
                glanceStrip

                // Hero Recommended Next Card
                if let task = viewModel?.topRecommendation {
                    recommendedHeroCard(task: task)
                } else if viewModel?.pendingCount == 0 {
                    allCaughtUpCard
                }

                // Up Next Queue
                if let upcoming = viewModel?.upcomingTasks, !upcoming.isEmpty {
                    upNextSection(tasks: upcoming)
                }

                // Daily Plan Quick Access Banner
                dailyPlanBanner
            }
            .padding(.horizontal, WNTheme.Spacing.lg)
            .padding(.vertical, WNTheme.Spacing.md)
        }
        .navigationTitle(viewModel?.greeting ?? "Good morning")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    appState?.selectedTab = .assistant
                } label: {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.accentColor)
                }
                .accessibilityLabel("AI Assistant")

                Button {
                    appState?.presentNewTaskEditor()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Task")

                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .onAppear {
            if let appState {
                if viewModel == nil {
                    viewModel = HomeViewModel(
                        taskService: appState.taskService,
                        categoryService: appState.categoryService,
                        preferenceService: appState.preferenceService,
                        planService: appState.planService
                    )
                }
                viewModel?.refresh()
            }
        }
        .onChange(of: appState?.activeFocusSession?.id) { _, _ in
            viewModel?.refresh()
        }
    }

    // MARK: - Active Session Detection

    private var currentActiveSession: WNFocusSession? {
        appState?.activeFocusSession ?? appState?.focusService.activeSession
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)).uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.8)

            if let subtitle = viewModel?.contextSubtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Live Focus Activity Card

    private func activeFocusCard(session: WNFocusSession) -> some View {
        Button {
            appState?.activeFocusSession = session
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Top status bar
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(appState?.focusService.isPaused == true ? Color.orange : Color.green)
                            .frame(width: 8, height: 8)

                        Text(appState?.focusService.isPaused == true ? "PAUSED" : "FOCUSING")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(appState?.focusService.isPaused == true ? .orange : .green)
                            .tracking(0.6)
                    }

                    Spacer()

                    Text((appState?.focusService.remainingTime ?? 0).formattedTimerCountdown)
                        .font(.headline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.accentColor)

                    Image(systemName: "chevron.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                // Task Title
                Text(session.task?.title ?? "Focus Session")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Linear Progress Bar
                let remainingTime = appState?.focusService.remainingTime ?? 0
                let totalSeconds = Double(max(1, session.plannedMinutes)) * 60.0
                let progress = max(0, min(1, CGFloat(1.0 - (remainingTime / totalSeconds))))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(uiColor: .tertiarySystemFill))
                            .frame(height: 6)

                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)

                // Quick Action Controls
                HStack(spacing: 12) {
                    Button {
                        if appState?.focusService.isPaused == true {
                            appState?.focusService.resumeSession()
                        } else {
                            appState?.focusService.pauseSession()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: appState?.focusService.isPaused == true ? "play.fill" : "pause.fill")
                                .font(.caption.weight(.semibold))
                            Text(appState?.focusService.isPaused == true ? "Resume" : "Pause")
                                .font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        appState?.focusService.endSession(completed: true)
                        viewModel?.refresh()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                            Text("Complete")
                                .font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.green)
                    }
                    .buttonStyle(.plain)
                }
            }
            .wnSchematicCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Glance Strip (3 Tiles)

    private var glanceStrip: some View {
        HStack(spacing: 10) {
            // Tile 1: Pending Tasks
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "checklist")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)

                    Spacer()

                    if let overdue = viewModel?.overdueCount, overdue > 0 {
                        Text("\(overdue)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red, in: Capsule())
                    }
                }

                Text("\(viewModel?.pendingCount ?? 0)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Pending")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .wnSchematicCard(padding: 12, cornerRadius: 14)

            // Tile 2: Daily Plan
            Button {
                appState?.selectedTab = .plan
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.purple)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }

                    Text(viewModel?.todayPlan != nil ? "\(viewModel?.todayPlan?.blocks.count ?? 0)" : "—")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(viewModel?.todayPlan != nil ? "Blocks Set" : "Plan Day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .wnSchematicCard(padding: 12, cornerRadius: 14)
            }
            .buttonStyle(.plain)

            // Tile 3: Done Today
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.green)

                    Spacer()
                }

                Text("\(viewModel?.completedTodayCount ?? 0)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Done Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .wnSchematicCard(padding: 12, cornerRadius: 14)
        }
    }

    // MARK: - Recommended Hero Card

    private func recommendedHeroCard(task: WNTask) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Eyebrow and menu
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                    Text("RECOMMENDED NEXT")
                        .font(.caption.weight(.bold))
                        .tracking(0.6)
                }
                .foregroundStyle(Color.accentColor)

                Spacer()

                Menu {
                    Button {
                        appState?.presentTaskEditor(for: task)
                    } label: {
                        Label("Edit Task", systemImage: "pencil")
                    }
                    Button {
                        appState?.postponeTask(task)
                        viewModel?.refresh()
                    } label: {
                        Label("Postpone", systemImage: "arrow.right.circle")
                    }
                    Button(role: .destructive) {
                        appState?.taskService.deleteTask(task)
                        viewModel?.refresh()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(4)
                }
            }

            // Task title
            Text(task.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            // Metadata Chips
            HStack(spacing: 8) {
                // Duration
                if task.effectiveEstimatedMinutes > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(task.effectiveEstimatedMinutes)m")
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
                }

                // Category
                if let category = task.category {
                    HStack(spacing: 4) {
                        Image(systemName: category.symbolName)
                            .font(.caption2)
                        Text(category.name)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(category.color.opacity(0.14), in: Capsule())
                }

                // Priority
                Text(task.priorityEnum.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(task.priorityEnum.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(task.priorityEnum.color.opacity(0.14), in: Capsule())

                // Overdue warning
                if task.isOverdue {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                        Text("Overdue")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.14), in: Capsule())
                }

                Spacer(minLength: 0)
            }

            // Subtask summary if available
            if !task.subtasks.isEmpty {
                let completed = task.subtasks.filter(\.isCompleted).count
                HStack(spacing: 6) {
                    ProgressView(value: Double(completed), total: Double(task.subtasks.count))
                        .tint(Color.accentColor)
                    Text("\(completed)/\(task.subtasks.count) subtasks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Action Buttons
            HStack(spacing: 12) {
                Button {
                    appState?.startFocus(for: task)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.subheadline.weight(.bold))
                        Text("Start Focus")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    appState?.completeTask(task)
                    viewModel?.refresh()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.green)
                        .frame(width: 52, height: 48)
                        .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Complete Task")
            }
        }
        .wnSchematicCard(cornerRadius: 20)
    }

    // MARK: - Up Next Section

    private func upNextSection(tasks: [WNTask]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("UP NEXT")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(0.6)

            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    HStack(spacing: 12) {
                        // Priority color bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(task.priorityEnum.color)
                            .frame(width: 4, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            HStack(spacing: 6) {
                                if let category = task.category {
                                    Text(category.name)
                                        .font(.caption2)
                                        .foregroundStyle(category.color)
                                }

                                if task.effectiveEstimatedMinutes > 0 {
                                    Text("• \(task.effectiveEstimatedMinutes)m")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Spacer()

                        Button {
                            appState?.startFocus(for: task)
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Start Focus on \(task.title)")
                    }
                    .wnSchematicCard(padding: 12, cornerRadius: 12)
                }
            }
        }
    }

    // MARK: - Daily Plan Quick Banner

    private var dailyPlanBanner: some View {
        Button {
            appState?.selectedTab = .plan
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.purple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel?.dynamicPlanActionTitle ?? "Plan my day")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Build a realistic timeline for tasks and routines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .wnSchematicCard(padding: 14, cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - All Caught Up State

    private var allCaughtUpCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color.green)

            Text("All Caught Up")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            Text("You have no pending tasks. Enjoy your day or plan ahead!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .wnSchematicCard(cornerRadius: 20)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
