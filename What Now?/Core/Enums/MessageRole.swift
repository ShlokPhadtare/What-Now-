//
//  MessageRole.swift
//  What Now?
//

import Foundation

/// Role of a message in an AI conversation.
enum MessageRole: String, Codable, CaseIterable {
    case user
    case assistant
    case system
}
