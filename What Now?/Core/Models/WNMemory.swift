//
//  WNMemory.swift
//  What Now?
//

import Foundation
import SwiftData

/// Persistent, learned facts about the user from the AI assistant.
@Model
final class WNMemory {
    var id: UUID = UUID()
    var content: String
    var createdAt: Date = Date()
    
    init(content: String) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
    }
}
