//
//  OpenAIService.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 10.08.2025.
//

import Foundation

// MARK: - LLM Service Protocol
protocol LLMService {
    func send(messages: [ChatMessage]) async throws -> String
}

// MARK: - OpenAI Chat Completions Service (simple, non‑streaming)
final class OpenAIService: LLMService {
    struct ChatCompletionRequest: Encodable {
        let model: String
        let messages: [Message]
        struct Message: Encodable { let role: String; let content: String }
    }
    struct ChatCompletionResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let role: String; let content: String }
            let index: Int
            let message: Message
            let finish_reason: String?
        }
        let choices: [Choice]
    }

    private let apiKeyProvider: () -> String?
    private let model: String

    init(model: String = "gpt-4o-mini", apiKeyProvider: @escaping () -> String? = { KeychainHelper.shared.apiKey }) {
        self.model = model
        self.apiKeyProvider = apiKeyProvider
    }

    func send(messages: [ChatMessage]) async throws -> String {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody = ChatCompletionRequest(
            model: model,
            messages: messages.map { .init(role: $0.role.rawValue, content: $0.content) }
        )
        req.httpBody = try JSONEncoder().encode(requestBody)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw LLMError.httpError(status: (resp as? HTTPURLResponse)?.statusCode ?? -1, body: body)
        }
        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let text = decoded.choices.first?.message.content else {
            throw LLMError.emptyResponse
        }
        return text
    }
}
