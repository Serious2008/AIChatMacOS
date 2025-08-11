//
//  SystemPromptBuilder.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 11.08.2025.
//

import Foundation

let schemaString =
"""
{
  "version": "string",
  "status": "success|needs_clarification|error",
  "task_type": "qa|summarize|rewrite|classify|extract|plan|code|calc|other",
  "answer": {
    "text": "string|null",
    "items": ["any"],
    "structured": {}
  },
  "citations": ["string"],
  "follow_up_questions": ["string"],
  "clarifications_needed": ["string"],
  "error": { "code": "string|null", "message": "string|null" },
  "meta": { "language": "ru|en|…", "confidence": 0.0 }
}
"""

public struct UniversalSchemaConfig {
    public let version: String
    public let schemaJSON: String             // сама универсальная схема (как строка JSON)
    public let shortReminder: String?         // опционально: "Ответ строго по схеме v1.0, валидный JSON."

    public init(version: String, schemaJSON: String, shortReminder: String? = nil) {
        self.version = version
        self.schemaJSON = schemaJSON
        self.shortReminder = shortReminder
    }
}

public final class SystemPromptBuilder {
    private let cfg: UniversalSchemaConfig

    public init(config: UniversalSchemaConfig) {
        self.cfg = config
    }

    func buildMessages(
        userInput: String,
        chatHistory: [ChatMessage] = []
    ) -> [ChatMessage] {
        var messages: [ChatMessage] = []

        // 1) System — один и тот же якорь с версией и схемой
        let systemContent =
        """
        Ты — API и отвечаешь строго в JSON по схеме v\(cfg.version).
        Никакого текста вне JSON. Не добавляй поля помимо схемы.

        Схема (v\(cfg.version)):
        \(cfg.schemaJSON)
        """
        messages.append(.init(role: .system, content: systemContent))

        // 2) (опц.) developer — короткое напоминание
        if let reminder = cfg.shortReminder, !reminder.isEmpty {
            messages.append(.init(role: .developer, content: reminder))
        }

        // 3) История диалога (если есть)
        messages.append(contentsOf: chatHistory)

        // 4) Текущий пользовательский ввод
        let wrappedUser = "Входные данные: \(userInput)"
        messages.append(.init(role: .user, content: wrappedUser))

        return messages
    }
}
