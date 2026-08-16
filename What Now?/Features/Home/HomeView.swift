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
                    appState?.isAssistantPresented = true
                } label: {
                    Image(systemName: "sparkles")
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
            Text("ALL CAUGHT UP")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Text("You're all caught up.")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.primary)

            let hour = Calendar.current.component(.hour, from: Date())
            let timeString = hour < 12 ? "morning" : (hour < 17 ? "afternoon" : "evening")
            
            Text("Enjoy the rest of your \(timeString).")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: WNTheme.Spacing.md) {
                Button {
                    appState?.isAssistantPresented = true
                } label: {
                    HStack {
                        Text("Plan tomorrow")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(Color.accentColor)
                }
                
                Button(action: {
                    appState?.presentNewTaskEditor()
                }) {
                    HStack {
                        Text("Add a task")
                        Spacer()
                        Image(systemName: "plus")
                    }
                    .font(.headline)
                    .padding()
                    .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.primary)
                }
            }
            .padding(.top, WNTheme.Spacing.lg)
        }
        .padding(.top, WNTheme.Spacing.md)
    }

    @ViewBuilder
    private func nextMoveSection(_ task: WNTask, viewModel: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.lg) {
            
            Text("NEXT")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            
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
                    Text("·")
                    Text(task.priorityEnum.displayName)
                }
                .font(.title3)
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: WNTheme.Spacing.md) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        appState?.startFocus(for: task)
                        viewModel.refresh()
                    }
                } label: {
                    HStack {
                        Text("Start")
                        Spacer()
                        Image(systemName: "play.fill")
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.white)
                }

                Button {
                    appState?.selectedTab = .plan
                } label: {
                    Text("See today's plan")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.top, WNTheme.Spacing.md)
        }
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity.combined(with: .scale(scale: 0.95))))
    }

    @ViewBuilder
    private func activeFocusSection(_ session: WNFocusSession, remainingTime: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.lg) {
            
            Text("ACTIVE FOCUS")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)
            
            VStack(alignment: .leading, spacing: WNTheme.Spacing.sm) {
                Text(session.task?.title ?? "Focus Session")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: WNTheme.Spacing.sm) {
                    let totalSeconds = Double(max(1, session.plannedMinutes)) * 60.0
                    let progress = max(0, min(1, CGFloat(remainingTime / totalSeconds)))
                    
                    Text("\(remainingTime.formattedDuration) remaining")
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(.secondary)
                        
                    Spacer()
                }
            }

            HStack(spacing: WNTheme.Spacing.md) {
                Button(action: {
                    withAnimation {
                        appState?.endActiveFocusSession()
                        viewModel?.refresh()
                    }
                }) {
                    Text("Pause")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.primary)
                }

                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let task = session.task {
                            appState?.completeTask(task)
                        }
                        viewModel?.refresh()
                    }
                }) {
                    Text("Complete")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.top, WNTheme.Spacing.md)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5))
        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.05)), removal: .opacity.combined(with: .move(edge: .top))))
    }
}

