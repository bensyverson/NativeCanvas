//
//  ChatHistoryView.swift
//  VibePDF
//

import SwiftUI

struct ChatHistoryView: View {
    @Environment(DocumentCoordinator.self) private var coordinator

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(coordinator.messages) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 80)
            }
            .background(.clear)
            .onChange(of: coordinator.messages) { _, messages in
                if let last = messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }.transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ChatHistoryView()
        .environment(DocumentCoordinator())
        .background(Color.black.opacity(0.5))
}
