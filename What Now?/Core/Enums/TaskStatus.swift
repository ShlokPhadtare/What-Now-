//
//  TaskStatus.swift
//  What Now?
//

import Foundation

/// Lifecycle status of a task.
enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case inProgress
    case completed
    case abandoned

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: "Pending"
        case .inProgress: "In Progress"
        case .completed: "Completed"
        case .abandoned: "Abandoned"
        }
    }

    var symbolName: String {
        switch self {
        case .pending: "circle"
        case .inProgress: "circle.dotted.circle"
        case .completed: "checkmark.circle.fill"
        case .abandoned: "xmark.circle"
        }
    }

    /// Whether this status represents an active (non-terminal) state.
    var isActive: Bool {
        switch self {
        case .pending, .inProgress: true
        case .completed, .abandoned: false
        }
    }
}
