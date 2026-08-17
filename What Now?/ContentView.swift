//
//  RootView.swift
//  What Now?
//

import SwiftUI

/// The root view that switches between onboarding and the main tab interface.
struct RootView: View {
    @Environment(\.appState) private var appState

    var body: some View {
        if let appState {
            if appState.isOnboardingComplete {
                MainTabView()
                    .sheet(isPresented: Bindable(appState).isTaskEditorPresented) {
                        TaskEditorView(task: appState.taskToEdit)
                    }
            } else {
                // TODO: Phase 7 — OnboardingView
                // For now, auto-complete onboarding so the app is usable.
                MainTabView()
                    .onAppear {
                        appState.preferenceService.completeOnboarding()
                    }
                    .sheet(isPresented: Bindable(appState).isTaskEditorPresented) {
                        TaskEditorView(task: appState.taskToEdit)
                    }
            }
        }
    }
}

// MARK: - Main Tab View

/// The primary tab-based navigation structure with 4 core tabs.
struct MainTabView: View {
    @Environment(\.appState) private var appState

    var body: some View {
        if let appState = appState {
            TabView(selection: Bindable(appState).selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack {
                    HomeView()
                }
            }

            Tab("Plan", systemImage: "calendar", value: .plan) {
                NavigationStack {
                    PlanView()
                }
            }

            Tab("Tasks", systemImage: "checklist", value: .tasks) {
                NavigationStack {
                    TaskListView()
                }
            }

            Tab("AI", systemImage: "sparkles", value: .assistant) {
                AssistantView()
            }
        }
        .fullScreenCover(item: Bindable(appState).activeFocusSession) { session in
            FocusView()
        }
        }
    }
}

// MARK: - Tab Enum

enum AppTab: String, Hashable {
    case home
    case plan
    case tasks
    case assistant
}


