//
//  WNUserProfile.swift
//  What Now?
//

import Foundation
import SwiftData

/// The user's profile containing onboarding selections and preferences.
///
/// There should only ever be one `WNUserProfile` in the database.
@Model
final class WNUserProfile {
    var id: UUID = UUID()
    var name: String?
    var peakEnergyTime: String = TimeOfDay.morning.rawValue
    var preferredFocusMinutes: Int = 25
    var onboardingCompleted: Bool = false
    var createdAt: Date = Date()

    /// Comma-separated category interests from onboarding.
    var helpCategoriesRaw: String = ""

    /// Comma-separated obstacles from onboarding.
    var obstaclesRaw: String = ""

    /// Waking hour start (0–23), used by the scheduling engine.
    var dayStartHour: Int = 7

    /// Waking hour end (0–23), used by the scheduling engine.
    var dayEndHour: Int = 23

    // MARK: - Computed Properties

    var peakEnergyTimeEnum: TimeOfDay {
        get { TimeOfDay(rawValue: peakEnergyTime) ?? .morning }
        set { peakEnergyTime = newValue.rawValue }
    }

    var helpCategories: [String] {
        get { helpCategoriesRaw.split(separator: ",").map(String.init) }
        set { helpCategoriesRaw = newValue.joined(separator: ",") }
    }

    var obstacles: [String] {
        get { obstaclesRaw.split(separator: ",").map(String.init) }
        set { obstaclesRaw = newValue.joined(separator: ",") }
    }

    // MARK: - Init

    init() {
        self.id = UUID()
        self.createdAt = Date()
    }
}
