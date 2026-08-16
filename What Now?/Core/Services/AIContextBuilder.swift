//
//  AIContextBuilder.swift
//  What Now?
//

import Foundation

/// Intelligently constructs the necessary context for the AI Assistant,
/// avoiding dumping the entire database on every request.
struct AIContextBuilder {
    let taskService: TaskService
    let focusService: FocusService
    let preferenceService: PreferenceService
    let planService: PlanService
    let memoryService: MemoryService
    
    func buildContext(for query: String) -> String {
        let q = query.lowercased()
        var contextPieces: [String] = []
        
        // 1. Base Context (Time & State)
        let now = Date.now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        contextPieces.append("CURRENT DATE & TIME: \(formatter.string(from: now))")
        contextPieces.append("DAY OF WEEK: \(now.formatted(.dateTime.weekday(.wide)))")
        
        if let focusTask = focusService.activeSession?.task {
            contextPieces.append("CURRENT ACTIVE FOCUS: '\(focusTask.title)' (\(focusService.remainingTime.formattedDuration) remaining)")
        } else {
            contextPieces.append("CURRENT ACTIVE FOCUS: None")
        }
        
        // 2. Planning & Tasks Context
        if q.contains("what") || q.contains("do") || q.contains("plan") || q.contains("recommend") || q.contains("next") || q.contains("task") || q.contains("move") || q.contains("change") || q.contains("didn't") {
            let pending = taskService.pendingTasks()
            let todayPlan = planService.plan(for: now)
            
            let pendingSummary = pending.prefix(20).map { "- \($0.title) (\($0.estimatedMinutes?.formattedMinutes ?? "no duration"), \($0.priorityEnum.displayName))" }.joined(separator: "\n")
            contextPieces.append("PENDING TASKS (Top 20):\n\(pendingSummary.isEmpty ? "None" : pendingSummary)")
            
            if let plan = todayPlan, !plan.blocks.isEmpty {
                let planSummary = plan.sortedBlocks.map { "\($0.startTime.formatted(date: .omitted, time: .shortened)): \($0.title) (\($0.durationMinutes)m)" }.joined(separator: "\n")
                contextPieces.append("TODAY'S TIMELINE PLAN:\n\(planSummary)")
            } else {
                contextPieces.append("TODAY'S TIMELINE PLAN: Not generated yet.")
            }
        }
        
        // 3. History Context
        if q.contains("history") || q.contains("yesterday") || q.contains("completed") || q.contains("did i") {
            let completed = taskService.completedTasks()
            let historySummary = completed.prefix(15).map { "- \($0.title) (completed \($0.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? "unknown"))" }.joined(separator: "\n")
            contextPieces.append("RECENTLY COMPLETED TASKS:\n\(historySummary.isEmpty ? "None" : historySummary)")
        }
        
        // 4. Memory & Preferences Context
        let prefs = preferenceService.profile
        var prefString = "USER ONBOARDING PREFERENCES:\nPeak Energy: \(prefs.peakEnergyTimeEnum.displayName)\nPreferred Focus Duration: \(prefs.preferredFocusMinutes)m"
        
        let memories = memoryService.allMemories()
        if !memories.isEmpty {
            let memString = memories.map { "- \($0.content)" }.joined(separator: "\n")
            prefString += "\n\nLEARNED USER MEMORIES (LONG-TERM):\n\(memString)"
        }
        
        contextPieces.append(prefString)
        
        return contextPieces.joined(separator: "\n\n")
    }
}
