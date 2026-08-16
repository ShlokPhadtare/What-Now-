//
//  EnergyLevel.swift
//  What Now?
//

import Foundation

/// User's self-reported energy level, used to filter recommendation difficulty.
enum EnergyLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .normal: "Normal"
        case .high: "High"
        }
    }

    var symbolName: String {
        switch self {
        case .low: "battery.25percent"
        case .normal: "battery.50percent"
        case .high: "battery.100percent"
        }
    }
}
