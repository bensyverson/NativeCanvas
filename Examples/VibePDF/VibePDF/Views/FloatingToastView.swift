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

    var body: some View {
        VStack {
            Spacer()
            if let text = visibleText {
                Text(text)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 72)
                    .frame(minWidth: 50, maxWidth: 400)
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else if showThinking {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Thinking…")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                .padding(.bottom, 72)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: visibleText)
        .animation(.easeInOut(duration: 0.3), value: showThinking)
        .onChange(of: coordinator.messages) { _, messages in
            // If the user just sent a message, clear any lingering toast.
            if messages.last?.role == .user {
                cancelAndClear()
                return
            }

            guard let agentMsg = messages.last(where: { $0.role == .agent }) else { return }

            // Cancel any pending dismiss — new content is arriving.
            dismissTask?.cancel()
            dismissTask = nil
            visibleText = agentMsg.text

            if !agentMsg.isStreaming {
                scheduleDismiss()
            }
        }
    }

    private func cancelAndClear() {
        dismissTask?.cancel()
        dismissTask = nil
        withAnimation { visibleText = nil }
    }

    private func scheduleDismiss() {
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            withAnimation { visibleText = nil }
        }
    }
}

#Preview {
    FloatingToastView()
        .environment(DocumentCoordinator())
        .background(Color.black.opacity(0.5))
        .frame(height: 400)
}
