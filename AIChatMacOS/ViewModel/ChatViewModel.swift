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
    @Published var messages = [ChatMessage]()
    @Published var input: String = ""
    @Published var isSending = false
    @Published var errorMessage: String?

    var service: LLMService

    init(service: LLMService = OpenAIService()) {
        self.service = service
        self.messages.append(.init(role: .system, content: FirstAgent.systemMessage))
    }

    func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        input = ""
        isSending = true

        Task {
            do {
                let reply = try await service.send(messages: messages)
                messages.append(contentsOf: prepareServiceMessage(message: reply))
                
                if containsFirstAgentFinishedTag(reply) {
                    var messagesForSecondAgent = [ChatMessage]()
                    messagesForSecondAgent.append(.init(role: .system, content: SecondAgent.systemMessage))
                    messagesForSecondAgent.append(.init(role: .user, content: messages[messages.count - 2].content))
                    
                    let reply = try await service.send(messages: messagesForSecondAgent)
                    messages.append(contentsOf: prepareServiceMessage(message: reply))
                }
                
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isSending = false
        }
    }
    
    private func prepareServiceMessage(message: String) -> [ChatMessage] {
        
        var messages = [ChatMessage]()
        
        if containsFirstAgentFinishedTag(message) {
            let messageWithoutTag = message.replacingOccurrences(of: FirstAgent.finishedTag, with: "")
            messages.append(.init(role: .assistant, content: messageWithoutTag))
            messages.append(.init(role: .service, content: "Agent 1 Завершил работу"))
        } else if message.contains(SecondAgent.finishedTag) {
            let messageWithoutTag = message.replacingOccurrences(of: SecondAgent.finishedTag, with: "")
            messages.append(.init(role: .assistant, content: messageWithoutTag))
            messages.append(.init(role: .service, content: "Agent 2 Завершил работу"))
        } else {
            messages.append(.init(role: .assistant, content: message))
        }
        
        return messages
    }
    
    private func containsFirstAgentFinishedTag(_ message: String) -> Bool {
        return message.contains(FirstAgent.finishedTag)
    }
}
