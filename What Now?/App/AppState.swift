//
//  AppState.swift
//  What Now?
//

import Foundation
import SwiftUI
import SwiftData

/// Central service container and app-level state.
///
/// Injected into the SwiftUI environment at the App level.
/// All ViewModels receive their service dependencies from this container.
@Observable
final class AppState {
    let modelContext: ModelContext

    // MARK: - Services

    let taskService: TaskService
    let focusService: FocusService
    let categoryService: CategoryService
    let preferenceService: PreferenceService
    let planService: PlanService
    let memoryService: MemoryService
    let streakService: StreakService
    
    // AI Services
    let intelligenceRouter: IntelligenceRouter
    
    var aiService: AIServiceProtocol {
        return intelligenceRouter
    }

    // MARK: - App-Level State

    /// Global tab selection
    var selectedTab: AppTab = .home

    /// The currently active focus session, if any.
    var activeFocusSession: WNFocusSession?
    
    /// The current active chat session.
    var activeChatSession: WNChatSession?

    /// Whether the task editor sheet is presented.
    var isTaskEditorPresented: Bool = false

    /// Task to edit (nil = creating new task).
    var taskToEdit: WNTask?

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Initialize services with shared context
        self.taskService = TaskService(context: modelContext)
        self.focusService = FocusService(context: modelContext)
        self.categoryService = CategoryService(context: modelContext)
        self.memoryService = MemoryService(context: modelContext)
        self.streakService = StreakService()
        let prefService = PreferenceService(context: modelContext)
        self.preferenceService = prefService
        self.planService = PlanService(context: modelContext, taskService: taskService, preferenceService: prefService)
        
        self.intelligenceRouter = IntelligenceRouter(
            preferenceService: prefService,
            taskService: self.taskService,
            focusService: self.focusService,
            planService: self.planService,
            memoryService: self.memoryService
        )
        
        self.activeFocusSession = focusService.activeSession

        // Seed defaults on first launch
        categoryService.seedDefaultsIfNeeded()
    }

    // MARK: - Convenience

    var isOnboardingComplete: Bool {
        preferenceService.isOnboardingComplete
    }

    /// Present the task editor for creating a new task.
    func presentNewTaskEditor() {
        taskToEdit = nil
        isTaskEditorPresented = true
    }

    /// Present the task editor for editing an existing task.
    func presentTaskEditor(for task: WNTask) {
        taskToEdit = task
        isTaskEditorPresented = true
    }

    // MARK: - Task / Focus Coordination

    /// Starts a task and its persisted focus session as one user action.
    func startFocus(for task: WNTask) {
        guard activeFocusSession == nil else { return }
        taskService.startTask(task)
        activeFocusSession = focusService.startSession(for: task)
    }

    /// Completes a task and finishes its associated active focus session, if present.
    func completeTask(_ task: WNTask) {
        if activeFocusSession?.task?.id == task.id {
            focusService.endSession(completed: true)
            activeFocusSession = nil
        }
        taskService.completeTask(task)
    }

    /// Postpones a task and ends its associated session without completing it.
    func postponeTask(_ task: WNTask) {
        if activeFocusSession?.task?.id == task.id {
            focusService.endSession(completed: false)
            activeFocusSession = nil
        }
        taskService.postponeTask(task)
    }

    func endActiveFocusSession() {
        focusService.endSession(completed: false)
        activeFocusSession = nil
    }
}

// MARK: - Environment Key

extension EnvironmentValues {
    @Entry var appState: AppState? = nil
}
