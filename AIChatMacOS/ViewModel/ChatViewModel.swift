//
//  ChatViewModel.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 10.08.2025.
//

import Foundation

// MARK: - ViewModel
@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        .init(role: .system, content: "You are a helpful assistant.")
    ]
    @Published var input: String = ""
    @Published var isSending = false
    @Published var errorMessage: String?

    var service: LLMService

    init(service: LLMService = OpenAIService()) {
        self.service = service
    }

    func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        input = ""
        isSending = true
        
        let cfg = UniversalSchemaConfig(
            version: "1.0",
            schemaJSON: schemaString,
            shortReminder: "Ответ строго по схеме v1.0, один валидный JSON, без Markdown."
        )

        let builder = SystemPromptBuilder(config: cfg)

        // 1) Подготовка сообщений
        let messages = builder.buildMessages(
            userInput: trimmed,
            chatHistory: [] // сюда можно прокинуть историю чата при необходимости
        )
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        Task {
            do {
                let result: LLMResponse = try await service.send(
                    messages: messages,
                    decodeTo: LLMResponse.self,
                    jsonDecoder: decoder,
                    autoRepair: true // один ретрай на случай невалидного JSON
                )
                
                var resultMessage = result.answer.text ?? ""
                
                if result.status == .needsClarification {
                    resultMessage += "\(result.clarificationsNeeded.first ?? "")"
                }
                
                if !result.followUpQuestions.isEmpty {
                    result.followUpQuestions.forEach({
                        resultMessage += "\n\($0)"
                    })
                }
                
                
                self.messages.append(.init(role: .assistant, content: resultMessage))
                // обрабатываешь result.status / result.answer / result.meta и т.д.
//                print(result.status)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                print("OpenAI error: \(error)")
            }
            isSending = false
        }
    }
}
