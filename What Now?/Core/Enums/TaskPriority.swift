//
//  TaskPriority.swift
//  What Now?
//

import Foundation

/// Priority level for tasks, used in recommendation scoring.
enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high
    case critical

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .critical: "Critical"
        }
    }

    var symbolName: String {
        switch self {
        case .low: "arrow.down"
        case .medium: "minus"
        case .high: "arrow.up"
        case .critical: "exclamationmark.2"
        }
    }

    /// Weight used by the recommendation engine (0–100).
    var scoreWeight: Double {
        switch self {
        case .low: 25
        case .medium: 50
        case .high: 75
        case .critical: 100
        }
    }

    var sortOrder: Int {
        switch self {
        case .critical: 0
        case .high: 1
        case .medium: 2
        case .low: 3
        }
    }
}
