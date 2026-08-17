//
//  ChatMessage.swift
//  What Now?
//

import Foundation

enum MessageContent: Codable, Equatable {
    case text(String)
    case actionResult(title: String, duration: Int?, deadline: Date?, taskId: String?)
    case planProposal(blocks: [ProposedBlock])
    case planModification(actions: [PlanModification])
    case memorySaved(fact: String)
    case question(prompt: String, options: [String], expectedField: String)
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    let isUser: Bool
    let content: MessageContent
    var timestamp = Date()
    
    var text: String {
        switch content {
        case .text(let t): return t
        case .actionResult(let title, _, _, _): return "Created task: \(title)"
        case .planProposal: return "Proposed a plan."
        case .planModification: return "Modified the plan."
        case .memorySaved: return "Remembered a fact."
        case .question(let prompt, _, _): return prompt
        }
    }
}
