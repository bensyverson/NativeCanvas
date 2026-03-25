//
//  ChatHistoryView.swift
//  VibePDF
//

import SwiftUI

struct ChatHistoryView: View {
    @Environment(DocumentCoordinator.self) private var coordinator

    private var showThinking: Bool {
        guard coordinator.isAgentRunning else { return false }
        guard let last = coordinator.messages.last else { return true }
        return !(last.role == .agent && last.isStreaming)
    }

    private var thinkingLabel: String {
        coordinator.messages.last?.role == .toolCall ? "Working…" : "Thinking…"
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(coordinator.messages) { message in
                    ChatBubble(message: message)
                }
                if showThinking {
                    HStack {
                        ThinkingBubble(label: thinkingLabel)
                        Spacer(minLength: 48)
                    }
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(.clear)
        .defaultScrollAnchor(.bottom)
        .animation(.easeInOut(duration: 0.2), value: showThinking)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ChatHistoryView()
        .environment(DocumentCoordinator())
        .background(Color.black.opacity(0.5))
}
