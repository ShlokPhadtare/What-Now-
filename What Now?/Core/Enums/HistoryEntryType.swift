//
//  HistoryEntryType.swift
//  What Now?
//

import Foundation

/// The type of activity recorded in the history log.
enum HistoryEntryType: String, Codable, CaseIterable, Identifiable {
    case taskCompleted
    case taskPostponed
    case taskAbandoned
    case focusCompleted
    case focusAbandoned
    case dayReview

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .taskCompleted: "Task Completed"
        case .taskPostponed: "Task Postponed"
        case .taskAbandoned: "Task Abandoned"
        case .focusCompleted: "Focus Completed"
        case .focusAbandoned: "Focus Abandoned"
        case .dayReview: "Day Review"
        }
    }

    var symbolName: String {
        switch self {
        case .taskCompleted: "checkmark.circle.fill"
        case .taskPostponed: "arrow.uturn.right"
        case .taskAbandoned: "xmark.circle"
        case .focusCompleted: "target"
        case .focusAbandoned: "xmark.octagon"
        case .dayReview: "text.book.closed"
        }
    }
}
