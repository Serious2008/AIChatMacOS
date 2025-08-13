//
//  SystemBubble.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 13.08.2025.
//

import SwiftUI

// MARK: - UI
struct SystemBubble: View {
    let message: ChatMessage

    var isAssistant: Bool { message.role == .assistant }

    var body: some View {
        HStack {
            if isAssistant { Spacer(minLength: 40) }
            Text(message.content)
                .textSelection(.enabled)
                .padding(7)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(12)
                .frame(maxWidth: 520, alignment: .leading)
            if !isAssistant { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
    }
}

#Preview {
    SystemBubble(message: .init(role: .assistant, content: "Agent 1 finished") )
}
