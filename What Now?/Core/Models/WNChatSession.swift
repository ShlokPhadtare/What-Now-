//
//  WNChatSession.swift
//  What Now?
//

import Foundation
import SwiftData

@Model
final class WNChatSession {
    var id: UUID = UUID()
    var title: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \WNChatMessage.session)
    var messages: [WNChatMessage] = []
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class WNChatMessage {
    var id: UUID = UUID()
    var isUser: Bool
    var timestamp: Date = Date()
    var contentData: Data = Data()
    
    var session: WNChatSession?
    
    @Transient
    @MainActor
    var content: MessageContent {
        get {
            if let decoded = try? JSONDecoder().decode(MessageContent.self, from: contentData) {
                return decoded
            }
            return .text("Error decoding message")
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                contentData = encoded
            }
        }
    }
    
    @Transient
    @MainActor
    var chatMessage: ChatMessage {
        ChatMessage(id: id, isUser: isUser, content: content, timestamp: timestamp)
    }
    
    @MainActor
    init(isUser: Bool, content: MessageContent) {
        self.id = UUID()
        self.isUser = isUser
        self.timestamp = Date()
        
        if let encoded = try? JSONEncoder().encode(content) {
            self.contentData = encoded
        }
    }
}
