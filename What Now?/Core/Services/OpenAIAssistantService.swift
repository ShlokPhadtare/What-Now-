//
//  OpenAIAssistantService.swift
//  What Now?
//

import Foundation

/// Implementation of AIServiceProtocol using OpenAI's API via BaseOpenAIService.
final class OpenAIAssistantService: BaseOpenAIService {
    
    let preferenceService: PreferenceService
    
    init(preferenceService: PreferenceService) {
        self.preferenceService = preferenceService
    }
    
    override var apiURL: URL {
        URL(string: "https://api.openai.com/v1/chat/completions")!
    }
    
    override var apiKey: String {
        preferenceService.getAPIKey(for: .openAI) ?? ""
    }
    
    override var modelName: String {
        "gpt-4o-mini" // Hardcoded default for OpenAI for now
    }
    
    override func processQuery(_ query: String, history: [AIChatMessage], context: String) async throws -> AIAssistantIntent {
        if apiKey.isEmpty {
            // Throw so the IntelligenceRouter's catch block fires and local fallback activates.
            throw URLError(.userAuthenticationRequired)
        }
        
        return try await super.processQuery(query, history: history, context: context)
    }
}
