//
//  LMStudioAssistantService.swift
//  What Now?
//

import Foundation

/// Implementation of AIServiceProtocol using a local LM Studio server.
final class LMStudioAssistantService: BaseOpenAIService {
    
    let preferenceService: PreferenceService
    
    init(preferenceService: PreferenceService) {
        self.preferenceService = preferenceService
    }
    
    override var apiURL: URL {
        var baseUrlString = preferenceService.lmStudioUrl
        if baseUrlString.hasSuffix("/") {
            baseUrlString.removeLast()
        }
        if !baseUrlString.hasSuffix("/v1") {
            baseUrlString += "/v1"
        }
        return URL(string: baseUrlString + "/chat/completions")!
    }
    
    override var apiKey: String {
        // LM Studio often doesn't need an API key, but we allow it just in case.
        preferenceService.getAPIKey(for: .lmStudio) ?? "lm-studio"
    }
    
    override var modelName: String {
        let saved = preferenceService.lmStudioModel
        return saved.isEmpty ? "local-model" : saved
    }
    
    /// Fetches available models from the local LM Studio server
    func fetchAvailableModels() async throws -> [String] {
        var baseUrlString = preferenceService.lmStudioUrl
        if baseUrlString.hasSuffix("/") {
            baseUrlString.removeLast()
        }
        if !baseUrlString.hasSuffix("/v1") {
            baseUrlString += "/v1"
        }
        
        let url = URL(string: baseUrlString + "/models")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(LMStudioModelsResponse.self, from: data)
        return apiResponse.data.map { $0.id }
    }
}

fileprivate struct LMStudioModelsResponse: Decodable {
    struct ModelData: Decodable {
        let id: String
    }
    let data: [ModelData]
}
