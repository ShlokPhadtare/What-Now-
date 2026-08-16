//
//  ChatMessage.swift
//  What Now?
//

import Foundation

enum MessageContent {
    case text(String)
    case actionResult(title: String, duration: Int?, deadline: Date?)
    case planProposal(blocks: [ProposedBlock])
    case planModification(actions: [PlanModification])
    case memorySaved(fact: String)
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let content: MessageContent
    
    var text: String {
        switch content {
        case .text(let t): return t
        case .actionResult(let title, _, _): return "Created task: \(title)"
        case .planProposal: return "Proposed a plan."
        case .planModification: return "Modified the plan."
        case .memorySaved: return "Remembered a fact."
        }
    }
}
