//
//  ThinkingBubble.swift
//  VibePDF
//

import SwiftUI

/// A spinner + label styled as an agent chat bubble.
struct ThinkingBubble: View {
    var label: String = "Thinking…"

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(label)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    VStack(spacing: 12) {
        ThinkingBubble()
        ThinkingBubble(label: "Working…")
    }
    .padding()
    .background(Color.black.opacity(0.5))
}
