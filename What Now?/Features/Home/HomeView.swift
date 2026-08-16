//
//  HomeView.swift
//  What Now?
//

import SwiftUI
import SwiftData

/// The primary screen answering "What should I do now?" with a calm, native interface.
struct HomeView: View {
    @Environment(\.appState) private var appState
    @State private var viewModel: HomeViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WNTheme.Spacing.xxl) {
                if let viewModel {
                    // Context / Status line under large navigation title
                    if !viewModel.contextSubtitle.isEmpty {
                        HStack(spacing: 8) {
                            Text(viewModel.contextSubtitle)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            if let streak = appState?.streakService.currentStreak, streak > 1 {
                                Text("\(streak) day streak")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15), in: Capsule())
                            }
                        }
                        .padding(.top, 4)
                    }

                    if let activeSession = appState?.activeFocusSession {
                        activeFocusSection(activeSession, remainingTime: appState?.focusService.remainingTime ?? 0)
                    } else if let topTask = viewModel.topRecommendation {
                        nextMoveSection(topTask, viewModel: viewModel)
                    } else {
                        allCaughtUpSection
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, WNTheme.Spacing.sm)
        }
        .navigationTitle(viewModel?.greeting ?? "What Now?")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState?.presentNewTaskEditor()
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState?.selectedTab = .plan
                } label: {
                    Image(systemName: "calendar")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                }
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

    // MARK: - Sections

    @ViewBuilder
    private var allCaughtUpSection: some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.md) {
            Text("You're all caught up.")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.primary)

            let hour = Calendar.current.component(.hour, from: Date())
            let timeString = hour < 12 ? "morning" : (hour < 17 ? "afternoon" : "evening")
            
            Text("Enjoy your \(timeString).")
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: WNTheme.Spacing.lg) {
                Button {
                    appState?.selectedTab = .ai
                } label: {
                    Text(viewModel?.dynamicPlanActionTitle ?? "Plan my day")
                        .font(.headline)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                
                Button("Add something") {
                    appState?.presentNewTaskEditor()
                }
                .font(.headline)
                .foregroundStyle(.secondary)
            }
            .padding(.top, WNTheme.Spacing.lg)
        }
        .padding(.top, WNTheme.Spacing.lg)
    }

    @ViewBuilder
    private func nextMoveSection(_ task: WNTask, viewModel: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.lg) {
            
            VStack(alignment: .leading, spacing: WNTheme.Spacing.xs) {
                Text(task.title)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    if let minutes = task.estimatedMinutes {
                        Text(minutes.formattedMinutes)
                    }
                    if task.estimatedMinutes != nil && task.deadline != nil {
                        Text("·")
                    }
                    if let deadline = task.deadline {
                        Text("Due \(deadline.relativeDay.lowercased())")
                            .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }
                }
                .font(.title3)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: WNTheme.Spacing.lg) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        appState?.startFocus(for: task)
                        viewModel.refresh()
                    }
                } label: {
                    Text("Start")
                        .font(.headline)
                        .frame(minWidth: 100)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)

                Button("Postpone") {
                    withAnimation {
                        appState?.postponeTask(task)
                        viewModel.refresh()
                    }
                }
                .font(.headline)
                .foregroundStyle(.secondary)
            }
            .padding(.top, WNTheme.Spacing.md)
        }
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity.combined(with: .scale(scale: 0.95))))
    }

    @ViewBuilder
    private func activeFocusSection(_ session: WNFocusSession, remainingTime: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.lg) {
            
            VStack(alignment: .leading, spacing: WNTheme.Spacing.sm) {
                Text(session.task?.title ?? "Focus Session")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: WNTheme.Spacing.md) {
                    let totalSeconds = Double(max(1, session.plannedMinutes)) * 60.0
                    let progress = max(0, min(1, CGFloat(remainingTime / totalSeconds)))
                    
                    ZStack {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.15), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: progress)
                    }
                    .frame(width: 24, height: 24)

                    Text(remainingTime.formattedDuration)
                        .font(.system(size: 56, weight: .ultraLight, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.primary)
                }
            }

            HStack(spacing: WNTheme.Spacing.lg) {
                Button {
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let task = session.task {
                            appState?.completeTask(task)
                        }
                        viewModel?.refresh()
                    }
                } label: {
                    Label("Complete", systemImage: "checkmark")
                        .font(.headline)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.green)
                .controlSize(.large)

                Button("Pause") {
                    withAnimation {
                        appState?.endActiveFocusSession()
                        viewModel?.refresh()
                    }
                }
                .font(.headline)
                .foregroundStyle(.secondary)
            }
            .padding(.top, WNTheme.Spacing.md)
        }
        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.05)), removal: .opacity.combined(with: .move(edge: .top))))
    }
}

