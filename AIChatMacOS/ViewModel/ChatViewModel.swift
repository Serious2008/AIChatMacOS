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
        .init(role: .system, content: """
                            Ты эксперт в составлении ТЗ для разработки приложений!
                            Проведи короткий опрос пользователя состоящий из 3 вопросов.
                            
                            - Какое приложение вы хотите сделать (утилита, транспорт, фитнес)
                            - Для какой платформы
                            - Основные функции

                            Вопросы задавай по одному, без рассуждений!

                            После сразу напиши короткое ТЗ для этого приложения!
""")
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

        Task {
            do {
                let reply = try await service.send(messages: messages)
                messages.append(.init(role: .assistant, content: reply))
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isSending = false
        }
    }
}
