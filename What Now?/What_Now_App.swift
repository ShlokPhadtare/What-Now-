//
//  What_Now_App.swift
//  What Now?
//
//  Created by Shlok Phadtare on 16/08/26.
//

import SwiftUI
import SwiftData

@main
struct What_Now_App: App {
    let container: ModelContainer
    @State private var appState: AppState

    init() {
        // Configure the ModelContainer with all model types.
        let schema = Schema([
            WNTask.self,
            WNSubtask.self,
            WNCategory.self,
            WNRoutine.self,
            WNScheduleBlock.self,
            WNDailyPlan.self,
            WNFocusSession.self,
            WNHistoryEntry.self,
            WNUserProfile.self,
            WNAIConversation.self,
            WNAIMessage.self,
        ])

        let config = ModelConfiguration(
            "WhatNow",
            schema: schema
        )

        do {
            let container = try ModelContainer(for: schema, configurations: config)
            self.container = container
            let context = container.mainContext
            self._appState = State(initialValue: AppState(modelContext: context))
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appState, appState)
        }
        .modelContainer(container)
    }
}
