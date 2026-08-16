//
//  WNHistoryEntry.swift
//  What Now?
//

import Foundation
import SwiftData

/// A log entry recording a user action (task completion, postponement, focus session, etc.).
///
/// `categoryName` is denormalized from the associated task for fast aggregation queries.
@Model
final class WNHistoryEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var entryType: String = ""
    var durationMinutes: Int?
    var categoryName: String?
    var notes: String?

    var task: WNTask?

    // MARK: - Computed Properties

    var entryTypeEnum: HistoryEntryType {
        get { HistoryEntryType(rawValue: entryType) ?? .taskCompleted }
        set { entryType = newValue.rawValue }
    }

    // MARK: - Init

    init(
        entryType: HistoryEntryType,
        task: WNTask? = nil,
        durationMinutes: Int? = nil,
        categoryName: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = Date()
        self.entryType = entryType.rawValue
        self.task = task
        self.durationMinutes = durationMinutes
        self.categoryName = categoryName ?? task?.category?.name
        self.notes = notes
    }
}
