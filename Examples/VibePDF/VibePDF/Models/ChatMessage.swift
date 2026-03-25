//
//  ChatMessage.swift
//  VibePDF
//

import Foundation
import NativeCanvas

enum ChatRole: String, Friendly {
    case user, agent, toolCall, system
}

struct ChatMessage: Identifiable, Friendly {
    let id: UUID
    var role: ChatRole
    var text: String
    var toolName: String?
    var isStreaming: Bool = false
}
