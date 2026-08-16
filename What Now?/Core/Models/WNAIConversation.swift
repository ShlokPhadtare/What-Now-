//
//  WNAIConversation.swift
//  What Now?
//

import Foundation
import SwiftData

/// A conversation session with the AI assistant.
@Model
final class WNAIConversation {
    var id: UUID = UUID()
    var title: String?
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \WNAIMessage.conversation)
    var messages: [WNAIMessage] = []

    /// Messages sorted by creation date.
    var sortedMessages: [WNAIMessage] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }

    init(title: String? = nil) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
    }
}

/// A single message within an AI conversation.
@Model
final class WNAIMessage {
    var id: UUID = UUID()
    var role: String = MessageRole.user.rawValue
    var content: String = ""
    var toolCallsRaw: Data?
    var createdAt: Date = Date()

    var conversation: WNAIConversation?

    var roleEnum: MessageRole {
        get { MessageRole(rawValue: role) ?? .user }
        set { role = newValue.rawValue }
    }

    init(
        role: MessageRole,
        content: String,
        conversation: WNAIConversation? = nil
    ) {
        self.id = UUID()
        self.role = role.rawValue
        self.content = content
        self.createdAt = Date()
        self.conversation = conversation
    }
}
