//
//  RecommendationEngine.swift
//  What Now?
//

import Foundation

/// Analyzes a list of pending tasks and determines the absolute best "next action"
/// based on deadlines, priorities, durations, and the user's current energy levels.
struct RecommendationEngine {
    
    struct ScoringWeights {
        static let overdue: Double = 50.0
        static let priorityCritical: Double = 40.0
        static let priorityHigh: Double = 20.0
        static let priorityMedium: Double = 5.0
        static let dueToday: Double = 30.0
        static let dueTomorrow: Double = 10.0
        static let energyMatch: Double = 15.0
        static let quickTask: Double = 10.0 // < 15 mins
        static let inProgress: Double = 25.0
    }
    
    /// Returns the single best recommended task.
    static func topRecommendation(from tasks: [WNTask], currentProfile: WNUserProfile) -> WNTask? {
        guard !tasks.isEmpty else { return nil }
        
        // Find tasks currently being worked on
        if let active = tasks.first(where: { $0.statusEnum == .inProgress }) {
            return active
        }
        
        var bestTask: WNTask?
        var highestScore: Double = -Double.greatestFiniteMagnitude
        
        let now = Date.now
        let currentEnergy = currentEnergyLevel(given: currentProfile.peakEnergyTimeEnum, at: now)
        
        for task in tasks {
            let score = scoreTask(task, at: now, currentEnergy: currentEnergy)
            if score > highestScore {
                highestScore = score
                bestTask = task
            }
        }
        
        return bestTask
    }
    
    /// Score an individual task. Higher is better.
    private static func scoreTask(_ task: WNTask, at date: Date, currentEnergy: TimeOfDay) -> Double {
        var score: Double = 0.0
        
        // 1. Deadline urgency
        if task.isOverdue {
            score += ScoringWeights.overdue
        } else if let deadline = task.deadline {
            if deadline.isToday {
                score += ScoringWeights.dueToday
            } else if deadline.isTomorrow {
                score += ScoringWeights.dueTomorrow
            }
        }
        
        // 2. Priority
        switch task.priorityEnum {
        case .critical: score += ScoringWeights.priorityCritical
        case .high: score += ScoringWeights.priorityHigh
        case .medium: score += ScoringWeights.priorityMedium
        case .low: break
        }
        
        // 3. Energy / Time of Day Match
        if let preferred = task.preferredTimeEnum, preferred == currentEnergy {
            score += ScoringWeights.energyMatch
        }
        
        // 4. Quick wins
        if let duration = task.estimatedMinutes, duration <= 15 {
            score += ScoringWeights.quickTask
        }
        
        // 5. Postponement penalty (avoid picking tasks the user keeps avoiding, unless they are critical)
        if task.postponementCount > 0 {
            score -= Double(task.postponementCount) * 2.0
        }
        
        return score
    }
    
    /// Determine the user's current contextual energy level (Morning/Afternoon/Evening)
    private static func currentEnergyLevel(given peak: TimeOfDay, at date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .anytime
        }
    }
}
