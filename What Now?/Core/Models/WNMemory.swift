//
//  WNMemory.swift
//  What Now?
//

import Foundation
import SwiftData

/// Represents the category of a memory.
enum WNMemoryCategory: String, Codable, CaseIterable {
    case aboutMe = "About Me"
    case preferences = "Preferences"
    case habits = "Habits"
    case goals = "Goals"
    case routine = "Routine"
    case workStudy = "Work/Study"
    case other = "Other"
}

/// Persistent, learned facts about the user from the AI assistant.
@Model
final class WNMemory {
    var id: UUID = UUID()
    var content: String
    var categoryRaw: String
    var isEnabled: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var source: String = "User Conversation"
    var confidence: Double = 1.0
    
    var category: WNMemoryCategory {
        get { WNMemoryCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    init(content: String, category: WNMemoryCategory = .other) {
        self.id = UUID()
        self.content = content
        self.categoryRaw = category.rawValue
        self.isEnabled = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
