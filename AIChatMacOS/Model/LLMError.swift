//
//  LLMError.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 10.08.2025.
//

import Foundation

// MARK: - Errors
enum LLMError: LocalizedError {
    case missingAPIKey
    case emptyResponse
    case httpError(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Не задан API‑ключ OpenAI. Откройте Settings и вставьте ключ."
        case .emptyResponse: return "Модель вернула пустой ответ."
        case .httpError(let status, let body): return "HTTP \(status). \n\(body)"
        }
    }
}
