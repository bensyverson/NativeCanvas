//
//  AgentCursorView.swift
//  VibePDF
//

import SwiftUI

/// A floating cursor indicator showing agent activity at a document location.
struct AgentCursorView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: "arrow.up.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text("Agent")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 4))
        }
    }
}

#Preview {
    AgentCursorView()
        .padding()
        .background(Color.gray.opacity(0.3))
}
