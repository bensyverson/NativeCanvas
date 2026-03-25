//
//  FloatingToastView.swift
//  VibePDF
//

import SwiftUI

struct FloatingToastView: View {
    @Environment(DocumentCoordinator.self) private var coordinator
    @State private var visibleText: String? = nil
    @State private var dismissTask: Task<Void, Never>? = nil

    private var showThinking: Bool {
        coordinator.isAgentRunning && visibleText == nil
    }

    private var thinkingLabel: String {
        coordinator.messages.last?.role == .toolCall ? "Working…" : "Thinking…"
    }

    var body: some View {
        VStack {
            Spacer()
            if let text = visibleText {
                Text(Self.attributed(text))
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .frame(minWidth: 50, maxWidth: 400)
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else if showThinking {
                ThinkingBubble(label: thinkingLabel)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: visibleText)
        .animation(.easeInOut(duration: 0.3), value: showThinking)
        // When the agent starts running, immediately clear any stale toast so
        // the ThinkingBubble can appear without waiting for a messages change.
        .onChange(of: coordinator.isAgentRunning) { _, running in
            if running {
                cancelAndClear()
            } else if let last = coordinator.messages.last(where: { $0.role == .agent || $0.role == .error }) {
                // Agent finished — show final message (or error) then auto-dismiss.
                visibleText = last.text.trimmingCharacters(in: .whitespacesAndNewlines)
                scheduleDismiss()
            }
        }
        // While running, keep the toast in sync with the streaming agent message.
        .onChange(of: coordinator.messages) { _, messages in
            guard coordinator.isAgentRunning else { return }
            // A new user message means a fresh send — clear any stale toast
            // so the ThinkingBubble can appear (handles rapid re-sends where
            // isAgentRunning stays true and its onChange doesn't fire).
            if let last = messages.last, last.role == .user {
                cancelAndClear()
                return
            }
            // Tool calls clear the toast so the ThinkingBubble can show.
            if let last = messages.last, last.role == .toolCall {
                cancelAndClear()
                return
            }
            guard let agentMsg = messages.last(where: { $0.role == .agent }) else { return }
            if agentMsg.isStreaming {
                dismissTask?.cancel()
                dismissTask = nil
                visibleText = agentMsg.text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if visibleText != nil {
                // Agent finished streaming text but is still running (about to
                // think or call a tool). Linger briefly so the user can read,
                // then clear so the ThinkingBubble can appear.
                scheduleLinger()
            }
        }
    }

    private func cancelAndClear() {
        dismissTask?.cancel()
        dismissTask = nil
        withAnimation { visibleText = nil }
    }

    /// Keeps the current toast visible briefly, then clears it so the
    /// ThinkingBubble can appear while the agent is still running.
    private func scheduleLinger() {
        guard dismissTask == nil else { return }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            withAnimation { visibleText = nil }
            dismissTask = nil
        }
    }

    private func scheduleDismiss() {
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            withAnimation { visibleText = nil }
        }
    }

    private static func attributed(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
        )
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

#Preview {
    FloatingToastView()
        .environment(DocumentCoordinator())
        .background(Color.black.opacity(0.5))
        .frame(height: 400)
}
