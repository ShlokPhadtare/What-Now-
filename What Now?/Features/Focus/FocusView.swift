//
//  FocusView.swift
//  What Now?
//

import SwiftUI
import SwiftData

/// Dedicated view for managing the active Focus session.
struct FocusView: View {
    @Environment(\.appState) private var appState
    @State private var showingExitConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if let session = appState?.activeFocusSession {
                    activeSessionContent(session)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if appState?.activeFocusSession != nil {
                            showingExitConfirmation = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
            .confirmationDialog("Leave this focus session?", isPresented: $showingExitConfirmation, titleVisibility: .visible) {
                Button("Leave", role: .destructive) {
                    appState?.pauseActiveFocusSession()
                    dismiss()
                }
                Button("Keep Working", role: .cancel) { }
            }
        }
    }
    
    @State private var breathingScale: CGFloat = 1.0
    
    @ViewBuilder
    private func activeSessionContent(_ session: WNFocusSession) -> some View {
        let remainingTime = appState?.focusService.remainingTime ?? 0
        let totalSeconds = Double(max(1, session.plannedMinutes)) * 60.0
        let progress = max(0, min(1, CGFloat(remainingTime / totalSeconds)))
        let isPaused = appState?.isFocusPaused ?? false
        
        VStack(spacing: WNTheme.Spacing.xxl) {
            Spacer()
            
            Text(session.task?.title ?? "Focus Session")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, WNTheme.Spacing.xxl)
            
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(isPaused ? Color.secondary : Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                    .scaleEffect(isPaused ? 1.0 : breathingScale)
                    .animation(isPaused ? .spring(response: 0.3) : .easeInOut(duration: 2).repeatForever(autoreverses: true), value: isPaused ? 1.0 : breathingScale)
                
                VStack {
                    Text(remainingTime.formattedDuration)
                        .font(.system(size: 64, weight: .ultraLight, design: .rounded).monospacedDigit())
                    
                    if isPaused {
                        Text("Paused")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    } else if let endTime = session.plannedEndTime as Date? {
                        Text("Until \(endTime.formatted(date: .omitted, time: .shortened))")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 280, height: 280)
            
            HStack(spacing: WNTheme.Spacing.xl) {
                Button(action: {
                    HapticManager.shared.playRigid()
                    withAnimation {
                        if isPaused {
                            appState?.resumeActiveFocusSession()
                        } else {
                            appState?.pauseActiveFocusSession()
                        }
                    }
                }) {
                    Text(isPaused ? "Resume" : "Pause")
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            isPaused ? Color.accentColor.opacity(0.15) : Color(uiColor: .tertiarySystemFill),
                            in: Capsule()
                        )
                        .foregroundStyle(isPaused ? Color.accentColor : .primary)
                }
                
                Button(action: {
                    HapticManager.shared.playSuccess()
                    withAnimation {
                        if let task = session.task {
                            appState?.completeTask(task)
                        }
                        dismiss()
                    }
                }) {
                    Text("Complete")
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.green, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            
            Spacer()
        }
        .onAppear {
            if !appState!.isFocusPaused {
                breathingScale = 1.02
            }
        }
        .onChange(of: appState?.isFocusPaused ?? false) { _, paused in
            if paused {
                breathingScale = 1.0
            } else {
                breathingScale = 1.02
            }
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: WNTheme.Spacing.md) {
            Image(systemName: "target")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(Color.accentColor)
            
            Text("No Active Focus")
                .font(.title2.weight(.semibold))
            
            Text("Start a task from Home or Tasks to begin a focus session.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
