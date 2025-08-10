//
//  SettingsView.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 10.08.2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = KeychainHelper.shared.apiKey ?? ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OpenAI API Key").font(.headline)
            TextField("sk-...", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 420)
            Text("Ключ хранится в системном Keychain. Его можно создать на platform.openai.com → API Keys.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Save") {
                    KeychainHelper.shared.saveAPIKey(apiKey)
                }
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
        .padding(24)
        .frame(minWidth: 520)
    }
}

#Preview {
    SettingsView()
}
