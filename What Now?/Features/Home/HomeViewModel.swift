//
//  HomeViewModel.swift
//  What Now?
//

import Foundation

/// ViewModel for the Home screen.
///
/// Computes the adaptive greeting, top recommendation, pending counts,
/// and available categories for quick actions.
@Observable
final class HomeViewModel {
    private let taskService: TaskService
    private let categoryService: CategoryService
    private let preferenceService: PreferenceService
    private let planService: PlanService

    // MARK: - Published State

    var greeting: String = ""
    var contextSubtitle: String = ""
    var dynamicPlanActionTitle: String = "Plan my day"
    var userName: String?
    var topRecommendation: WNTask?
    var upcomingTasks: [WNTask] = []
    var pendingCount: Int = 0
    var overdueCount: Int = 0
    var completedTodayCount: Int = 0
    var todayPlan: WNDailyPlan?
    var categories: [WNCategory] = []

    // MARK: - Init

    init(
        taskService: TaskService,
        categoryService: CategoryService,
        preferenceService: PreferenceService,
        planService: PlanService
    ) {
        self.taskService = taskService
        self.categoryService = categoryService
        self.preferenceService = preferenceService
        self.planService = planService
    }

    // MARK: - Refresh

    func refresh() {
        greeting = Date.now.greetingText
        userName = preferenceService.profile.name

        let pending = taskService.pendingTasks()
        pendingCount = pending.count
        overdueCount = pending.filter(\.isOverdue).count

        let completed = taskService.completedTasks()
        completedTodayCount = completed.filter {
            guard let completedAt = $0.completedAt else { return false }
            return Calendar.current.isDateInToday(completedAt)
        }.count

        let hour = Calendar.current.component(.hour, from: Date())
        
        // Plan action dynamic title
        let plan = planService.plan(for: .now)
        todayPlan = plan
        if pendingCount == 0 {
            dynamicPlanActionTitle = "Plan tomorrow"
        } else if plan != nil {
            dynamicPlanActionTitle = "Adjust today's plan"
        } else if hour < 12 {
            dynamicPlanActionTitle = "Plan my day"
        } else if hour < 17 {
            dynamicPlanActionTitle = "Plan the rest of my day"
        } else {
            dynamicPlanActionTitle = "Plan my evening"
        }

        if pendingCount == 0 {
            if hour < 12 {
                contextSubtitle = "Your morning is clear."
            } else if hour < 17 {
                contextSubtitle = "Your afternoon is clear."
            } else {
                contextSubtitle = "Your evening is clear."
            }
        } else if pendingCount == 1 {
            contextSubtitle = "One thing left to tackle."
        } else {
            contextSubtitle = "\(pendingCount) tasks queued for today."
        }

        // Recommendation
        let top = computeSimpleRecommendation(from: pending)
        topRecommendation = top

        if let top {
            upcomingTasks = Array(pending.filter { $0.id != top.id }.prefix(3))
        } else {
            upcomingTasks = Array(pending.prefix(3))
        }

        // Categories that have at least one pending task
        let allCategories = categoryService.allCategories()
        let categoryIDs = Set(pending.compactMap { $0.category?.id })
        categories = allCategories.filter { categoryIDs.contains($0.id) }
    }

    // MARK: - Simple Recommendation (replaced by RecommendationEngine in Phase 2)

    private func computeSimpleRecommendation(from tasks: [WNTask]) -> WNTask? {
        RecommendationEngine.topRecommendation(from: tasks, currentProfile: preferenceService.profile)
    }
}
