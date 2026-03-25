//
//  ChatBubble.swift
//  VibePDF
//

import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 48)
                bubbleText(message.text)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            }
        case .agent:
            HStack {
                bubbleText(message.text)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                Spacer(minLength: 48)
            }
        case .toolCall:
            HStack {
                Label(
                    toolTitle(message.toolName ?? message.text),
                    systemImage: "chevron.right",
                ).font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 10)
                    .background(.regularMaterial)
                    .clipShape(.capsule)
                Spacer()
            }
        case .system:
            HStack {
                Text(message.text)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 10)
                    .background(.regularMaterial)
                    .clipShape(.capsule)
                Spacer()
            }
        case .error:
            HStack {
                Label(message.text, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.red.opacity(0.75))
                    .clipShape(.capsule)
                Spacer()
            }
        }
    }

    private func toolTitle(_ text: String) -> String {
        switch text {
        case "write_script":
            "Create document"
        case "edit_script":
            "Edit document"
        case "view_canvas":
            "View document"
        default:
            "Working"
        }
    }

    private func bubbleText(_ text: String) -> some View {
        Text(Self.attributed(text.trimmingCharacters(in: .whitespacesAndNewlines)))
            .frame(maxWidth: 400, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
    }

    private static func attributed(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
        )
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

#Preview {
    VStack(spacing: 8) {
        ChatBubble(message: ChatMessage(id: UUID(), role: .user, text: "Draw a red circle on white background"))
        ChatBubble(message: ChatMessage(id: UUID(), role: .agent, text: "I'll create that for you now. Used **nc.roundRect** with `r: 20` and set `fillStyle` to red."))
        ChatBubble(message: ChatMessage(id: UUID(), role: .toolCall, text: "write_script", toolName: "write_script"))
        ChatBubble(message: ChatMessage(id: UUID(), role: .system, text: "Session started"))
        ChatBubble(message: ChatMessage(id: UUID(), role: .error, text: "Rate limit exceeded. Please try again."))
    }
    .padding()
    .background(Color.black.opacity(0.6))
}
