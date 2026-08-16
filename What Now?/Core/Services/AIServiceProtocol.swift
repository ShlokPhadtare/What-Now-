//
//  AIServiceProtocol.swift
//  What Now?
//

import Foundation

/// Defines the intents the AI can return to operate the application.
enum AIAssistantIntent {
    case chatResponse(message: String)
    case planDay // Legacy
    case proposePlan(blocks: [ProposedBlock])
    case modifyPlan(actions: [PlanModification])
    case remember(fact: String)
    case createTask(title: String, durationMinutes: Int?, deadline: Date?)
    case startFocus(taskTitleFragment: String)
    case getRecommendations
}

struct ProposedBlock: Decodable {
    let title: String
    let startTimeIso: String // e.g. "2023-10-31T18:00:00Z"
    let durationMinutes: Int
}

struct PlanModification: Decodable {
    let originalTitleFragment: String
    let newStartTimeIso: String?
    let newDurationMinutes: Int?
}

/// A structured chat message to pass to the provider.
struct AIChatMessage {
    let role: String // "user", "assistant", "system"
    let content: String
}

/// Core interface for the What Now? intelligence engine.
protocol AIServiceProtocol: AnyObject {
    /// Send a natural language query and conversation history, returning an intent for the app to execute.
    func processQuery(_ query: String, history: [AIChatMessage], context: String) async throws -> AIAssistantIntent
}
