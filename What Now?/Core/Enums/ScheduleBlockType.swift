//
//  ScheduleBlockType.swift
//  What Now?
//

import Foundation
import SwiftUI

/// The type of a time block within a daily plan.
enum ScheduleBlockType: String, Codable, CaseIterable, Identifiable {
    case task
    case routine
    case calendarEvent
    case breakTime
    case freeTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .task: "Task"
        case .routine: "Routine"
        case .calendarEvent: "Event"
        case .breakTime: "Break"
        case .freeTime: "Free Time"
        }
    }

    var symbolName: String {
        switch self {
        case .task: "checkmark.circle"
        case .routine: "arrow.triangle.2.circlepath"
        case .calendarEvent: "calendar"
        case .breakTime: "cup.and.saucer"
        case .freeTime: "sparkles"
        }
    }
}
