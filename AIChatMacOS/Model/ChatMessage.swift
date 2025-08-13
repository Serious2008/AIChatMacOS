//
//  ChatMessage.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 10.08.2025.
//

import Foundation

struct ChatMessage: Identifiable, Equatable, Codable {
    enum Role: String, Codable {
        case system, user, assistant, service
    }
    var id = UUID()
    let role: Role
    var content: String
}
