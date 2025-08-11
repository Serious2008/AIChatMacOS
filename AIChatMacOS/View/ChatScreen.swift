//
//  ChatScreen.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 10.08.2025.
//

import SwiftUI

struct ChatScreen: View {
    @StateObject private var vm = ChatViewModel()
    @FocusState private var focused: Bool
    @State private var showingSettings = false
    @State private var inputHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("AI Chat MacOS")
                    .font(.headline)
                Spacer()
                Button("Settings") { showingSettings = true }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.messages) { msg in
                            if msg.role != .system { ChatBubble(message: msg) }
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: vm.messages.count) { _ in
                    withAnimation { proxy.scrollTo(vm.messages.last?.id, anchor: .bottom) }
                }
            }

            Divider()

            HStack(alignment: .bottom, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    GrowingTextView(text: $vm.input, calculatedHeight: $inputHeight, maxHeight: 140)
                        .frame(height: max(28, inputHeight))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .focused($focused)
                    if vm.input.isEmpty {
                        Text("Напишите сообщение…")
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
                Button(action: vm.send) {
                    if vm.isSending { ProgressView().controlSize(.small) } else { Text("Send") }
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(vm.isSending || vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .frame(minWidth: 640, minHeight: 520)
        .alert("Error", isPresented: Binding(get: { vm.errorMessage != nil }, set: { _ in vm.errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onAppear { focused = true }
    }
}

#Preview {
    ChatScreen()
}
