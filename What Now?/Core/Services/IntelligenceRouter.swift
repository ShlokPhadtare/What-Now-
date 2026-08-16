//
//  IntelligenceRouter.swift
//  What Now?
//

import Foundation
import SwiftData

/// Routes conversational intents through the best available intelligence layer.
/// Level 3: External AI (LM Studio/OpenAI)
/// Level 2: Apple On-Device Intelligence (Fallback)
/// Level 1: Deterministic Local Assistant (Fallback)
final class IntelligenceRouter: AIServiceProtocol {
    private let preferenceService: PreferenceService
    private let openAIService: OpenAIAssistantService
    private let lmStudioService: LMStudioAssistantService
    private let localAssistantService: LocalAssistantService
    
    init(preferenceService: PreferenceService,
         taskService: TaskService,
         focusService: FocusService,
         planService: PlanService,
         memoryService: MemoryService) {
        self.preferenceService = preferenceService
        self.openAIService = OpenAIAssistantService(preferenceService: preferenceService)
        self.lmStudioService = LMStudioAssistantService(preferenceService: preferenceService)
        self.localAssistantService = LocalAssistantService(
            taskService: taskService,
            planService: planService,
            memoryService: memoryService,
            preferenceService: preferenceService
        )
    }
    
    var externalService: AIServiceProtocol {
        switch preferenceService.aiProvider {
        case .openAI: return openAIService
        case .lmStudio: return lmStudioService
        }
    }
    
    func processQuery(_ query: String, history: [AIChatMessage], context: String) async throws -> AIAssistantIntent {
        // First try the local assistant for deterministic actions that don't need cloud/AI.
        // E.g., if it's explicitly part of a state machine or an exact match.
        if let localIntent = try? await localAssistantService.processQuery(query, history: history, context: context) {
            // Local assistant handled it deterministically (e.g. state machine advanced, or explicit command)
            return localIntent
        }
        
        // Next, try external AI (Level 3)
        do {
            return try await externalService.processQuery(query, history: history, context: context)
        } catch {
            print("External AI failed: \(error), falling back to local heuristic routing...")
            // Fallback to purely heuristic routing (Level 1)
            // (In iOS 18 we would insert Level 2 Apple Foundation Models here)
            return try await localAssistantService.processFallback(query: query)
        }
    }
    
    func injectLocalStateResponse(intent: AIAssistantIntent) {
        localAssistantService.injectIntent(intent)
    }
}
