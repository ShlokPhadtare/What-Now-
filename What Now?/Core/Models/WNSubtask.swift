//
//  WNSubtask.swift
//  What Now?
//

import Foundation
import SwiftData

/// A subtask within a parent `WNTask`, used for task decomposition.
@Model
final class WNSubtask {
    var id: UUID = UUID()
    var title: String = ""
    var estimatedMinutes: Int?
    var isCompleted: Bool = false
    var completedAt: Date?
    var sortOrder: Int = 0

    var parentTask: WNTask?

    init(
        title: String,
        estimatedMinutes: Int? = nil,
        sortOrder: Int = 0,
        parentTask: WNTask? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.sortOrder = sortOrder
        self.parentTask = parentTask
    }
}
