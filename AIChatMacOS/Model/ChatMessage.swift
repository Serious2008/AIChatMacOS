//
//  ChatMessage.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 10.08.2025.
//

import Foundation

enum Role: String, Codable {
    case system, user, assistant, developer
}

struct ChatMessage: Identifiable, Equatable, Codable {
    var id = UUID()
    let role: Role
    var content: String
    
    enum CodingKeys: String, CodingKey {
        case role, content //, temperature
    }
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let responseFormat: ResponseFormat
//    let temperature: Double?

    enum CodingKeys: String, CodingKey {
        case model, messages//, temperature
        case responseFormat = "response_format"
    }

    public struct ResponseFormat: Codable {
        public let type: String // "json_object"
    }
}

struct ChatResponse: Codable {
    struct Choice: Codable {
        public struct Msg: Codable {
            let role: Role
            let content: String
        }
        let index: Int
        let message: Msg
        let finish_reason: String?
    }
    let id: String?
    let choices: [Choice]
}
