//
//  IntelligenceRouter.swift
//  What Now?
//

import Foundation
import SwiftData

/// Tracks the current reachability state of the configured AI provider.
enum ProviderConnectionStatus: Equatable {
    case unknown
    case connected
    case unavailable
    
    var displayName: String {
        switch self {
        case .unknown: return "Checking..."
        case .connected: return "Connected"
        case .unavailable: return "Unavailable"
        }
    }
}

/// Routes conversational intents through the best available intelligence layer.
///
/// Priority:
///   Level 3: External AI (LM Studio / OpenAI) — tried FIRST when configured
///   Level 1: Deterministic Local Assistant — fallback when external is unavailable
@Observable
final class IntelligenceRouter: AIServiceProtocol {
    private let preferenceService: PreferenceService
    let openAIService: OpenAIAssistantService
    let lmStudioService: LMStudioAssistantService
    private let localAssistantService: LocalAssistantService
    
    /// Observable status of the currently selected external provider.
    private(set) var providerStatus: ProviderConnectionStatus = .unknown
    
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
    
    /// The currently configured external service.
    var externalService: AIServiceProtocol {
        switch preferenceService.aiProvider {
        case .openAI: return openAIService
        case .lmStudio: return lmStudioService
        }
    }
    
    /// True when the local assistant is mid-clarification flow (must be handled locally).
    var isAwaitingClarification: Bool {
        localAssistantService.isAwaitingClarification
    }
    
    // MARK: - Main Entry Point
    
    func processQuery(_ query: String, history: [AIChatMessage], context: String) async throws -> AIAssistantIntent {
        let lowerQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 1. If we are already in a local multi-step clarification flow, always route there first.
        //    This preserves conversation state and prevents the external AI from interrupting a flow.
        if localAssistantService.isAwaitingClarification {
            return try await localAssistantService.processQuery(query, history: history, context: context)
        }
        
        // 2. Handle explicit cancel at any point.
        if lowerQuery == "cancel" || lowerQuery == "stop" || lowerQuery == "nevermind" || lowerQuery == "× cancel" {
            if let localIntent = try? await localAssistantService.processQuery(query, history: history, context: context) {
                return localIntent
            }
        }
        
        // 3. Try External AI (Level 3) for natural conversation and complex planning
        do {
            let intent = try await externalService.processQuery(query, history: history, context: context)
            await updateProviderStatus(.connected)
            return intent
        } catch {
            print("External AI failed: \(error), falling back to local assistant...")
            await updateProviderStatus(.unavailable)
        }
        
        // 4. Fallback: Deterministic Local Assistant (Level 1)
        return try await localAssistantService.processFallback(query: query)
    }
    
    // MARK: - Provider Reachability
    
    /// Quickly checks if the configured provider is reachable.
    /// For LM Studio: 3-second GET to /v1/models.
    /// For OpenAI: checks if API key is set.
    @discardableResult
    func checkProviderReachability() async -> ProviderConnectionStatus {
        switch preferenceService.aiProvider {
        case .openAI:
            let key = preferenceService.getAPIKey(for: .openAI) ?? ""
            let status: ProviderConnectionStatus = key.isEmpty ? .unavailable : .unknown
            await updateProviderStatus(status)
            return status
            
        case .lmStudio:
            var baseUrlString = preferenceService.lmStudioUrl
            if baseUrlString.hasSuffix("/") { baseUrlString.removeLast() }
            if baseUrlString.hasSuffix("/v1") { baseUrlString = String(baseUrlString.dropLast(3)) }
            guard let url = URL(string: baseUrlString + "/v1/models") else {
                await updateProviderStatus(.unavailable)
                return .unavailable
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 3
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    await updateProviderStatus(.connected)
                    return .connected
                } else {
                    await updateProviderStatus(.unavailable)
                    return .unavailable
                }
            } catch {
                await updateProviderStatus(.unavailable)
                return .unavailable
            }
        }
    }
    
    @MainActor
    private func updateProviderStatus(_ status: ProviderConnectionStatus) {
        providerStatus = status
    }
    
    func injectLocalStateResponse(intent: AIAssistantIntent) {
        localAssistantService.injectIntent(intent)
    }
}
