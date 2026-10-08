//
//  FocusView.swift
//  What Now?
//

import SwiftUI
import SwiftData

/// Dedicated view for managing the active Focus session with Apple-precision timer and schematic controls.
struct FocusView: View {
    @Environment(\.appState) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var showingExitConfirmation = false
    @State private var breathingScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                // Ambient Radial Glow
                ambientGlowBackground

                VStack(spacing: 0) {
                    // Pinned Header Bar
                    headerBar

                    // Session or Empty Content
                    if let session = appState?.activeFocusSession ?? appState?.focusService.activeSession {
                        activeSessionContent(session)
                    } else {
                        emptyState
                    }
                }
            }
            .navigationBarHidden(true)
            .confirmationDialog("Focus Session Options", isPresented: $showingExitConfirmation, titleVisibility: .visible) {
                Button("Minimize (Keep Running)") {
                    dismiss()
                }

                Button("Pause & Leave") {
                    appState?.pauseActiveFocusSession()
                    dismiss()
                }

                Button("End Session Early", role: .destructive) {
                    appState?.endActiveFocusSession()
                    dismiss()
                }

                Button("Keep Working", role: .cancel) { }
            }
        }
    }

    // MARK: - Ambient Background

    @ViewBuilder
    private var ambientGlowBackground: some View {
        let isPaused = appState?.isFocusPaused ?? false
        if let _ = appState?.activeFocusSession ?? appState?.focusService.activeSession, !isPaused {
            RadialGradient(
                colors: [Color.accentColor.opacity(0.12), Color.clear],
                center: .center,
                startRadius: 80,
                endRadius: 420
            )
            .scaleEffect(breathingScale)
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: breathingScale)
            .ignoresSafeArea()
        }
    }

    // MARK: - Header Bar

    @ViewBuilder
    private var headerBar: some View {
        let isPaused = appState?.isFocusPaused ?? false

        HStack {
            // Minimize / Back Button
            Button {
                HapticManager.shared.playSelection()
                if appState?.activeFocusSession != nil {
                    showingExitConfirmation = true
                } else {
                    dismiss()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                    Text("Minimize")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5)
                )
            }

            Spacer()

            // Status Badge
            HStack(spacing: 6) {
                Circle()
                    .fill(isPaused ? Color.orange : Color.green)
                    .frame(width: 7, height: 7)

                Text(isPaused ? "PAUSED" : "FOCUSING")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isPaused ? Color.orange : Color.green)
                    .tracking(0.6)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                (isPaused ? Color.orange : Color.green).opacity(0.12),
                in: Capsule()
            )

            Spacer()

            // Quick Options Menu
            Menu {
                Button {
                    HapticManager.shared.playSoft()
                    if let session = appState?.activeFocusSession ?? appState?.focusService.activeSession {
                        withAnimation {
                            session.plannedMinutes += 5
                            appState?.taskService.save()
                        }
                    }
                } label: {
                    Label("Add 5 Minutes", systemImage: "plus.circle")
                }

                if let task = appState?.activeFocusSession?.task {
                    Button {
                        HapticManager.shared.playRigid()
                        withAnimation {
                            appState?.postponeTask(task)
                            dismiss()
                        }
                    } label: {
                        Label("Postpone Task", systemImage: "arrow.right.circle")
                    }
                }

                Button(role: .destructive) {
                    appState?.endActiveFocusSession()
                    dismiss()
                } label: {
                    Label("End Without Completing", systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Active Session Content

    @ViewBuilder
    private func activeSessionContent(_ session: WNFocusSession) -> some View {
        let remainingTime = appState?.focusService.remainingTime ?? 0
        let totalSeconds = Double(max(1, session.plannedMinutes)) * 60.0
        let progress = max(0, min(1, CGFloat(remainingTime / totalSeconds)))
        let isPaused = appState?.isFocusPaused ?? false

        ScrollView {
            VStack(spacing: WNTheme.Spacing.xl) {
                // Task Telemetry Header Card
                taskTelemetryCard(session: session)
                    .padding(.top, WNTheme.Spacing.xs)

                // Schematic Precision Timer Dial
                precisionTimerDial(
                    session: session,
                    remainingTime: remainingTime,
                    progress: progress,
                    isPaused: isPaused
                )

                // In-Session Subtasks Checklist (if task has subtasks)
                if let task = session.task, !task.subtasks.isEmpty {
                    subtasksChecklistSection(task: task)
                }

                // Tactile Control Bar
                controlsBar(session: session, isPaused: isPaused)
                    .padding(.top, WNTheme.Spacing.sm)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, WNTheme.Spacing.xxl)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            if !(appState?.isFocusPaused ?? false) {
                breathingScale = 1.03
            }
        }
        .onChange(of: appState?.isFocusPaused ?? false) { _, paused in
            if paused {
                breathingScale = 1.0
            } else {
                breathingScale = 1.03
            }
        }
    }

    // MARK: - Task Telemetry Card

    @ViewBuilder
    private func taskTelemetryCard(session: WNFocusSession) -> some View {
        VStack(spacing: 8) {
            Text(session.task?.title ?? "Focus Session")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)

            // Chips Row
            HStack(spacing: 6) {
                if let categoryName = session.categoryName {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(session.task?.category?.color ?? Color.accentColor)
                            .frame(width: 6, height: 6)
                        Text(categoryName)
                    }
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (session.task?.category?.color ?? Color.accentColor).opacity(0.12),
                        in: Capsule()
                    )
                    .foregroundStyle(session.task?.category?.color ?? Color.accentColor)
                }

                if let priority = session.task?.priorityEnum {
                    Text(priority.displayName)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priority.color.opacity(0.12), in: Capsule())
                        .foregroundStyle(priority.color)
                }

                Label("\(session.plannedMinutes)m target", systemImage: "timer")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Precision Timer Dial

    @ViewBuilder
    private func precisionTimerDial(
        session: WNFocusSession,
        remainingTime: TimeInterval,
        progress: CGFloat,
        isPaused: Bool
    ) -> some View {
        ZStack {
            // Background Track
            Circle()
                .stroke(Color(uiColor: .tertiarySystemFill), lineWidth: 10)

            // Active Arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isPaused ? Color.secondary : Color.accentColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
                .shadow(
                    color: (isPaused ? Color.clear : Color.accentColor).opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 0
                )

            // Center Content
            VStack(spacing: 4) {
                Text(remainingTime.formattedTimerCountdown)
                    .font(.system(size: 58, weight: .thin, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)

                if isPaused {
                    Text("Session Paused")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                } else if let endTime = session.plannedEndTime as Date? {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("Until \(endTime.formatted(date: .omitted, time: .shortened))")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                }

                // Progress Percentage
                let elapsedRatio = max(0, min(1, 1.0 - progress))
                Text("\(Int(elapsedRatio * 100))% completed")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .frame(width: 270, height: 270)
        .padding(.vertical, WNTheme.Spacing.sm)
    }

    // MARK: - In-Session Subtasks Checklist

    @ViewBuilder
    private func subtasksChecklistSection(task: WNTask) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.sm) {
            let progress = task.subtaskProgress
            HStack {
                Text("SUBTASKS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)

                Spacer()

                Text("\(progress.completed) of \(progress.total)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                ForEach(task.subtasks.sorted { $0.sortOrder < $1.sortOrder }) { subtask in
                    HStack(spacing: 10) {
                        Button {
                            HapticManager.shared.playSuccess()
                            withAnimation {
                                subtask.isCompleted.toggle()
                                subtask.completedAt = subtask.isCompleted ? Date() : nil
                                appState?.taskService.save()
                            }
                        } label: {
                            Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(subtask.isCompleted ? Color.green : Color.secondary)
                        }
                        .buttonStyle(.plain)

                        Text(subtask.title)
                            .font(.subheadline)
                            .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                            .strikethrough(subtask.isCompleted)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(WNTheme.Spacing.md)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(uiColor: .separator).opacity(0.25), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Controls Bar

    @ViewBuilder
    private func controlsBar(session: WNFocusSession, isPaused: Bool) -> some View {
        VStack(spacing: WNTheme.Spacing.md) {
            HStack(spacing: WNTheme.Spacing.md) {
                // Pause / Resume Button
                Button {
                    HapticManager.shared.playRigid()
                    withAnimation {
                        if isPaused {
                            appState?.resumeActiveFocusSession()
                        } else {
                            appState?.pauseActiveFocusSession()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.headline)
                        Text(isPaused ? "Resume" : "Pause")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        isPaused ? Color.accentColor.opacity(0.15) : Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5)
                    )
                    .foregroundStyle(isPaused ? Color.accentColor : .primary)
                }

                // Complete Button
                Button {
                    HapticManager.shared.playSuccess()
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let task = session.task {
                            appState?.completeTask(task)
                        } else {
                            appState?.endActiveFocusSession()
                        }
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.headline.weight(.bold))
                        Text("Complete")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
                }
            }

            // Quick +5 Min Extension Button
            Button {
                HapticManager.shared.playSoft()
                withAnimation {
                    session.plannedMinutes += 5
                    appState?.taskService.save()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                        .font(.caption.weight(.semibold))
                    Text("Add 5 Minutes")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: WNTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 90, height: 90)

                Image(systemName: "target")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 6) {
                Text("No Active Focus")
                    .font(.title2.weight(.bold))

                Text("Select a task from Home or Tasks to begin a dedicated focus session.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                dismiss()
            } label: {
                Text("Return to Dashboard")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }

            Spacer()
        }
    }
}
