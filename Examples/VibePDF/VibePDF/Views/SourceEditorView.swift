//
//  SourceEditorView.swift
//  VibePDF
//

import SwiftUI

struct SourceEditorView: View {
    @Environment(DocumentCoordinator.self) private var coordinator
    @State private var source: String = ""

    private var statusColor: Color {
        guard coordinator.jsScript != nil else { return .secondary }
        return coordinator.renderError == nil ? .green : .red
    }

    private var statusText: String {
        guard coordinator.jsScript != nil else { return "No script" }
        return coordinator.renderError ?? "Valid"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            #if os(macOS)
            CodeEditorView(text: $source)
            #else
            TextEditor(text: $source)
                .font(.system(.body, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .scrollContentBackground(.hidden)
                .background(.background)
            #endif
        }
        .onAppear {
            source = coordinator.jsScript ?? ""
        }
        .onChange(of: coordinator.jsScript) { _, new in
            let updated = new ?? ""
            if updated != source {
                source = updated
            }
        }
        .onChange(of: source) { _, new in
            coordinator.jsScript = new.isEmpty ? nil : new
            coordinator.rerender()
        }
    }
}

#Preview {
    SourceEditorView()
        .environment(DocumentCoordinator())
}
