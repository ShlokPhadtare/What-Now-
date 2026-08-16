//
//  PreferenceService.swift
//  What Now?
//

import Foundation
import SwiftData

/// Manages the user profile singleton and preferences.
@Observable
final class PreferenceService {
    private let context: ModelContext

    /// The active user profile. Loaded or created on init.
    private(set) var profile: WNUserProfile

    init(context: ModelContext) {
        self.context = context

        // Load or create the singleton profile.
        let descriptor = FetchDescriptor<WNUserProfile>()
        if let existing = try? context.fetch(descriptor).first {
            self.profile = existing
        } else {
            let newProfile = WNUserProfile()
            context.insert(newProfile)
            try? context.save()
            self.profile = newProfile
        }
    }

    // MARK: - Onboarding

    var isOnboardingComplete: Bool {
        profile.onboardingCompleted
    }

    func completeOnboarding(
        name: String? = nil,
        peakEnergy: TimeOfDay = .morning,
        focusMinutes: Int = 25,
        helpCategories: [String] = [],
        obstacles: [String] = []
    ) {
        profile.name = name
        profile.peakEnergyTimeEnum = peakEnergy
        profile.preferredFocusMinutes = focusMinutes
        profile.helpCategories = helpCategories
        profile.obstacles = obstacles
        profile.onboardingCompleted = true
        try? context.save()
    }

    // MARK: - Preferences

    func updatePeakEnergy(_ time: TimeOfDay) {
        profile.peakEnergyTimeEnum = time
        try? context.save()
    }

    func updatePreferredFocusDuration(_ minutes: Int) {
        profile.preferredFocusMinutes = minutes
        try? context.save()
    }

    func updateWakingHours(start: Int, end: Int) {
        profile.dayStartHour = start
        profile.dayEndHour = end
        try? context.save()
    }

    // MARK: - AI Configuration

    var aiProvider: AIProviderType {
        get {
            let saved = UserDefaults.standard.string(forKey: "AIProviderType") ?? AIProviderType.openAI.rawValue
            return AIProviderType(rawValue: saved) ?? .openAI
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "AIProviderType")
        }
    }

    var lmStudioUrl: String {
        get { UserDefaults.standard.string(forKey: "LMStudioUrl") ?? "http://127.0.0.1:1234/v1" }
        set { UserDefaults.standard.set(newValue, forKey: "LMStudioUrl") }
    }

    var lmStudioModel: String {
        get { UserDefaults.standard.string(forKey: "LMStudioModel") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "LMStudioModel") }
    }

    func saveAPIKey(for provider: AIProviderType, key: String) {
        if key.trimmingCharacters(in: .whitespaces).isEmpty {
            try? KeychainManager.delete(key: "API_KEY_\(provider.rawValue)")
        } else {
            try? KeychainManager.save(key: "API_KEY_\(provider.rawValue)", value: key)
        }
    }

    func getAPIKey(for provider: AIProviderType) -> String? {
        try? KeychainManager.get(key: "API_KEY_\(provider.rawValue)")
    }

    // MARK: - Privacy

    /// Delete all personalization data while preserving the profile.
    func resetPersonalization() {
        profile.helpCategoriesRaw = ""
        profile.obstaclesRaw = ""
        profile.peakEnergyTime = TimeOfDay.morning.rawValue
        profile.preferredFocusMinutes = 25
        profile.dayStartHour = 7
        profile.dayEndHour = 23
        try? context.save()
    }
}
