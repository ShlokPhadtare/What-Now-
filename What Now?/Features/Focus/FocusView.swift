//
//  FocusView.swift
//  What Now?
//

import SwiftUI
import SwiftData

/// Dedicated view for managing the active Focus session.
struct FocusView: View {
    @Environment(\.appState) private var appState
    
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
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    @ViewBuilder
    private func activeSessionContent(_ session: WNFocusSession) -> some View {
        let remainingTime = appState?.focusService.remainingTime ?? 0
        let totalSeconds = Double(max(1, session.plannedMinutes)) * 60.0
        let progress = max(0, min(1, CGFloat(remainingTime / totalSeconds)))
        
        VStack(spacing: WNTheme.Spacing.xxl) {
            Spacer()
            
            Text(session.task?.title ?? "Focus Session")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                VStack {
                    Text(remainingTime.formattedDuration)
                        .font(.system(size: 64, weight: .ultraLight, design: .rounded).monospacedDigit())
                    
                    if let endTime = session.plannedEndTime as Date? {
                        Text("Until \(endTime.formatted(date: .omitted, time: .shortened))")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 280, height: 280)
            
            HStack(spacing: WNTheme.Spacing.xl) {
                Button(action: {
                    withAnimation {
                        appState?.endActiveFocusSession()
                    }
                }) {
                    Text("Pause")
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
                        .foregroundStyle(.primary)
                }
                
                Button(action: {
                    withAnimation {
                        if let task = session.task {
                            appState?.completeTask(task)
                        }
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
