//
//  ChatBubble.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 10.08.2025.
//

import SwiftUI

// MARK: - UI
struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            Text(message.content)
                .textSelection(.enabled)
                .padding(12)
                .background(isUser ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.12))
                .cornerRadius(12)
                .frame(maxWidth: 520, alignment: .leading)
            if !isUser { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.horizontal)
    }
}

#Preview {
    ChatBubble(message: .init(role: .assistant, content: "Agent 1 finished") )
}
