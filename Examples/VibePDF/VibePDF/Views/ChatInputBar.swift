//
//  ChatInputBar.swift
//  VibePDF
//

import SwiftUI

struct ChatInputBar: View {
    @Environment(DocumentCoordinator.self) private var coordinator
    @Binding var inputText: String

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    coordinator.showHistory.toggle()
                }
            } label: {
                Image(systemName: "list.bullet")
                    .imageScale(.medium)
            }.buttonStyle(.plain)

            TextField("Message...", text: $inputText, axis: .vertical)
                .lineLimit(1 ... 4)
                .onSubmit {
                    sendMessage()
                }
                .controlSize(.large)

            Button {
                if coordinator.isAgentRunning {
                    coordinator.stop()
                } else {
                    sendMessage()
                }
            } label: {
                Image(
                    systemName: coordinator.isAgentRunning
                        ? "stop.circle.fill"
                        : "arrow.up.circle.fill",
                )
                .imageScale(.large)
            }.buttonStyle(.plain)
                .disabled(inputText.isEmpty && !coordinator.isAgentRunning)
        }
        .frame(maxWidth: 400)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        coordinator.send(text)
    }
}

#Preview {
    VStack {
        Spacer()
        ChatInputBar(inputText: .constant("Hello world"))
            .environment(DocumentCoordinator())
    }
    .background(Color.gray.opacity(0.3))
}
