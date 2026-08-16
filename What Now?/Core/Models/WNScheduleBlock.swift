//
//  WNScheduleBlock.swift
//  What Now?
//

import Foundation
import SwiftData

/// A time block within a daily plan.
///
/// Represents a task, routine, calendar event, break, or free time
/// positioned at a specific time slot in the day.
@Model
final class WNScheduleBlock {
    var id: UUID = UUID()
    var date: Date = Date()
    var startTime: Date = Date()
    var endTime: Date = Date()
    var title: String = ""
    var blockType: String = ScheduleBlockType.freeTime.rawValue
    var isCompleted: Bool = false
    var calendarEventIdentifier: String?

    var linkedTask: WNTask?
    var linkedRoutine: WNRoutine?
    var dailyPlan: WNDailyPlan?

    // MARK: - Computed Properties

    var blockTypeEnum: ScheduleBlockType {
        get { ScheduleBlockType(rawValue: blockType) ?? .freeTime }
        set { blockType = newValue.rawValue }
    }

    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    // MARK: - Init

    init(
        date: Date,
        startTime: Date,
        endTime: Date,
        title: String,
        blockType: ScheduleBlockType,
        linkedTask: WNTask? = nil,
        linkedRoutine: WNRoutine? = nil,
        calendarEventIdentifier: String? = nil
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.startTime = startTime
        self.endTime = endTime
        self.title = title
        self.blockType = blockType.rawValue
        self.linkedTask = linkedTask
        self.linkedRoutine = linkedRoutine
        self.calendarEventIdentifier = calendarEventIdentifier
    }
}
