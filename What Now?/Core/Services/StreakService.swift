//
//  StreakService.swift
//  What Now?
//

import Foundation
import SwiftUI

/// A lightweight service for tracking planning consistency.
@Observable
final class StreakService {
    private let defaults = UserDefaults.standard
    private let streakKey = "wn_planning_streak"
    private let lastPlanDateKey = "wn_last_plan_date"

    var currentStreak: Int = 0

    init() {
        loadStreak()
    }

    private func loadStreak() {
        let savedStreak = defaults.integer(forKey: streakKey)
        if savedStreak == 0 {
            currentStreak = 0
            return
        }

        guard let lastDate = defaults.object(forKey: lastPlanDateKey) as? Date else {
            currentStreak = 0
            return
        }

        let calendar = Calendar.current
        if calendar.isDateInToday(lastDate) {
            currentStreak = savedStreak
        } else if calendar.isDateInYesterday(lastDate) {
            currentStreak = savedStreak
        } else {
            // Streak broken
            currentStreak = 0
            saveStreak()
        }
    }

    func recordPlanCreated() {
        let calendar = Calendar.current
        let today = Date.now

        if let lastDate = defaults.object(forKey: lastPlanDateKey) as? Date {
            if calendar.isDateInToday(lastDate) {
                // Already recorded today
                return
            } else if calendar.isDateInYesterday(lastDate) {
                // Continue streak
                currentStreak += 1
            } else {
                // Streak broken, start new
                currentStreak = 1
            }
        } else {
            // First time
            currentStreak = 1
        }

        defaults.set(today, forKey: lastPlanDateKey)
        saveStreak()
    }

    private func saveStreak() {
        defaults.set(currentStreak, forKey: streakKey)
    }
}
