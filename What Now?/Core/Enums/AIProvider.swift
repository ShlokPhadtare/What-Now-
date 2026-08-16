//
//  AIProvider.swift
//  What Now?
//

import Foundation

enum AIProviderType: String, Codable, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case lmStudio = "LM Studio"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .lmStudio: return "LM Studio (Local)"
        }
    }
}
