//
//  HapticManager.swift
//  What Now?
//

import SwiftUI
import UIKit

/// Centralized manager for a cohesive haptic language across the app.
@MainActor
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// Used when a task is completed, or a major positive action occurs.
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Used when an option is selected, date picker is moved, or minor UI element tapped.
    func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Used for subtle transitions, like entering Focus mode.
    func playSoft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    /// Used for cancellations, pausing, or structural navigation changes.
    func playRigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    /// Used for errors or denied actions.
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
