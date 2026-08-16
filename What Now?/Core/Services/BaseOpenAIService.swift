//
//  BaseOpenAIService.swift
//  What Now?
//

import Foundation

class BaseOpenAIService: AIServiceProtocol {
    
    // To be overridden by subclasses
    var apiURL: URL { fatalError("Must override apiURL") }
    var apiKey: String { fatalError("Must override apiKey") }
    var modelName: String { fatalError("Must override modelName") }
    
    func processQuery(_ query: String, history: [AIChatMessage], context: String) async throws -> AIAssistantIntent {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        
        let token = apiKey
        if !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
        You are the 'What Now?' intelligent day-management assistant.
        The user will ask you to perform actions or ask for advice.
        
        Context about the user's current state:
        \(context)
        
        BEHAVIOR RULES:
        1. MULTI-ITEM PLANNING: If the user asks to plan their day/evening, or gives a time limit ("I only have two hours"), DO NOT output a single task. Output `proposePlan` with a realistic sequence of scheduled blocks.
        2. SMART REPLANNING: If the user says they missed a task, finished early, or wants to move something, DO NOT create a new duplicate task. Output `modifyPlan` to move/resize existing items based on their names.
        3. USER MEMORY: If the user explicitly states a preference (e.g. "I prefer studying after dinner", "I don't like mornings"), output `remember` so the system can save it long-term.
        4. SMART CLARIFICATION: If missing vital info, ask briefly using `chatResponse`. If sensible defaults exist, act immediately.
        5. TASK TITLE NORMALIZATION: When creating a task, extract the pure intent. (e.g. "Study python tomorrow for 30m" -> Title: "Study Python").
        
        Respond ONLY with a valid JSON object matching exactly ONE of these schemas:
        
        1. Action: Propose Plan (Multiple Items)
        {"intent": "proposePlan", "blocks": [{"title": "Gym", "startTimeIso": "2023-10-31T18:00:00Z", "durationMinutes": 60}, {"title": "Dinner", "startTimeIso": "2023-10-31T19:15:00Z", "durationMinutes": 30}]}
        
        2. Action: Modify Existing Plan
        {"intent": "modifyPlan", "actions": [{"originalTitleFragment": "dsa", "newStartTimeIso": "2023-10-31T20:30:00Z", "newDurationMinutes": 45}]}
        
        3. Action: Remember Preference
        {"intent": "remember", "fact": "User prefers studying after dinner"}
        
        4. Action: Create Single Task
        {"intent": "createTask", "title": "Normalized Title", "durationMinutes": 30, "deadlineIso": "2023-10-31T23:59:00Z"}
        
        5. Action: Start Focus
        {"intent": "startFocus", "taskTitleFragment": "dsa"}
        
        6. Action: Get Recommendations
        {"intent": "getRecommendations"}
        
        7. Action: Chat Response (Answer questions or clarify)
        {"intent": "chatResponse", "message": "Your helpful response here."}
        
        Never include markdown backticks around the JSON. Return only the raw JSON string.
        """
        
        var messagesPayload: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        for msg in history {
            messagesPayload.append(["role": msg.role, "content": msg.content])
        }
        
        messagesPayload.append(["role": "user", "content": query])
        
        let body: [String: Any] = [
            "model": modelName,
            "messages": messagesPayload,
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("API Error: \(errorJson)")
            }
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let jsonString = apiResponse.choices.first?.message.content else {
            throw URLError(.cannotParseResponse)
        }
        
        let cleanJson = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
        
        guard let responseData = cleanJson.data(using: .utf8) else {
            return .chatResponse(message: jsonString)
        }
        
        do {
            let parsed = try JSONDecoder().decode(AssistantJSONResponse.self, from: responseData)
            
            switch parsed.intent {
            case "proposePlan":
                return .proposePlan(blocks: parsed.blocks ?? [])
            case "modifyPlan":
                return .modifyPlan(actions: parsed.actions ?? [])
            case "remember":
                return .remember(fact: parsed.fact ?? "User preference")
            case "planDay": // Legacy fallback
                return .planDay
            case "createTask":
                var deadline: Date? = nil
                if let iso = parsed.deadlineIso {
                    let formatter = ISO8601DateFormatter()
                    deadline = formatter.date(from: iso)
                }
                return .createTask(title: parsed.title ?? "New Task", durationMinutes: parsed.durationMinutes, deadline: deadline)
            case "startFocus":
                return .startFocus(taskTitleFragment: parsed.taskTitleFragment ?? "")
            case "getRecommendations":
                return .getRecommendations
            case "chatResponse":
                return .chatResponse(message: parsed.message ?? "I'm not sure how to respond to that.")
            default:
                return .chatResponse(message: jsonString)
            }
        } catch {
            return .chatResponse(message: cleanJson)
        }
    }
}

// MARK: - API Decoding Models
fileprivate struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

fileprivate struct AssistantJSONResponse: Decodable {
    let intent: String
    let title: String?
    let durationMinutes: Int?
    let deadlineIso: String?
    let taskTitleFragment: String?
    let message: String?
    
    // New fields
    let blocks: [ProposedBlock]?
    let actions: [PlanModification]?
    let fact: String?
}
