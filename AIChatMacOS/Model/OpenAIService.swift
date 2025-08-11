//
//  OpenAIService.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 10.08.2025.
//

import Foundation

// MARK: - LLM Service Protocol
protocol LLMService {
    func send<T: Decodable>(messages: [ChatMessage],
                            decodeTo: T.Type,
                            jsonDecoder: JSONDecoder,
                            autoRepair: Bool) async throws -> T
}

// MARK: - OpenAI Chat Completions Service (simple, non‑streaming)
final class OpenAIService: LLMService {
    
//    struct ChatCompletionRequest: Encodable {
//        let model: String
//        let messages: [Message]
//        struct Message: Encodable { let role: String; let content: String }
//    }
//    struct ChatCompletionResponse: Decodable {
//        struct Choice: Decodable {
//            struct Message: Decodable { let role: String; let content: String }
//            let index: Int
//            let message: Message
//            let finish_reason: String?
//        }
//        let choices: [Choice]
//    }

    private let apiKeyProvider: String?
    private let model: String
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    init(model: String = "gpt-4o-mini", apiKeyProvider: @escaping () -> String? = { KeychainHelper.shared.apiKey }) {
        self.model = model
        self.apiKeyProvider = apiKeyProvider()
    }

    func send<T: Decodable>(messages: [ChatMessage],
                            decodeTo: T.Type,
                            jsonDecoder: JSONDecoder = .init(),
                            autoRepair: Bool = true
        ) async throws -> T {
        guard let apiKey = apiKeyProvider, !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }

        // 1) первичный запрос
        let primary = try await rawCompletion(messages: messages)
        let content = primary.choices.first?.message.content ?? ""
        print("LLM content >>>\n\(content)\n<<<")
        do {
            return try decode(content, as: T.self, using: jsonDecoder)
        } catch {
            guard autoRepair else { throw LLMError.invalidJSON(text: content) }
            // 2) авто‑ремонт (один ретрай)
            let repaired = try await repair(messages: messages, badPayload: content)
            return try decode(repaired, as: T.self, using: jsonDecoder)
        }
    }
    
    // MARK: - Internal

    private func rawCompletion(messages: [ChatMessage]) async throws -> ChatResponse {
        guard let apiKey = apiKeyProvider, !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }
        
        let reqBody = ChatRequest(
            model: model,
            messages: messages,
            responseFormat: .init(type: "json_object")//,
//            temperature: temperature
        )

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(reqBody)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
                        
            return try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch let e as DecodingError {
            print("Decode failed: \(prettyDecodeError(e))")
            throw e
//            throw LLMError.invalidJSON(text: e.errorDescription ?? "Unknown decoding error")
        } catch {
            throw LLMError.httpError(status: -1, body: error.localizedDescription)
        }
    }

    private func repair(messages: [ChatMessage], badPayload: String) async throws -> String {
        var repairMessages = messages
        // Добавляем строгую инструкцию повторить ответ ровно одним валидным JSON
        let repairNote =
        """
        Предыдущий ответ нарушил формат (невалидный JSON под схему). \
        Верни РОВНО ОДИН валидный JSON по утверждённой схеме, без текста до/после. \
        Не меняй имена ключей и типы. Исправь ошибки формата.
        Невалидный ответ:
        \(badPayload)
        """
        repairMessages.append(.init(role: .developer, content: repairNote))

        let resp = try await rawCompletion(messages: repairMessages)
        guard let content = resp.choices.first?.message.content else {
            throw LLMError.emptyResponse
        }
        return content
    }

    private func decode<T: Decodable>(_ content: String, as: T.Type, using decoder: JSONDecoder) throws -> T {
        
        guard let data = content.data(using: .utf8) else {
            throw LLMError.invalidJSON(text: "UTF8 encode failed")
        }
        return try decoder.decode(T.self, from: data)
    }
    
    private func prettyDecodeError(_ error: Error) -> String {
        guard let e = error as? DecodingError else { return String(describing: error) }
        switch e {
        case .typeMismatch(let type, let ctx):
            return "Type mismatch: \(type) at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")) — \(ctx.debugDescription)"
        case .valueNotFound(let type, let ctx):
            return "Value not found: \(type) at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")) — \(ctx.debugDescription)"
        case .keyNotFound(let key, let ctx):
            return "Key not found: \(key.stringValue) at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")) — \(ctx.debugDescription)"
        case .dataCorrupted(let ctx):
            return "Data corrupted at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")) — \(ctx.debugDescription)"
        @unknown default:
            return "Unknown DecodingError: \(e)"
        }
    }
}
