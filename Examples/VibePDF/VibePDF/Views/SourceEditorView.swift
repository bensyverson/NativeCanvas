//
//  SourceEditorView.swift
//  VibePDF
//

import SwiftUI

struct SourceEditorView: View {
    @Environment(DocumentCoordinator.self) private var coordinator
    @State private var source: String = ""
    @State private var scanPhase: CGFloat = 0

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

            ZStack {
                #if os(macOS)
                    CodeEditorView(
                        text: $source,
                        errorLine: coordinator.renderErrorLine,
                        highlightRange: coordinator.scriptHighlight?.lineRange,
                    )
                #else
                    TextEditor(text: $source)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .scrollContentBackground(.hidden)
                        .background(.background)
                #endif

                // Scan effect when agent reads the script
                if coordinator.isScanningScript {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color.blue.opacity(0.15), location: 0.45),
                            .init(color: Color.blue.opacity(0.30), location: 0.5),
                            .init(color: Color.blue.opacity(0.15), location: 0.55),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom,
                    )
                    .offset(y: (scanPhase - 0.5) * 600)
                    .allowsHitTesting(false)
                    .onAppear {
                        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                            scanPhase = 1
                        }
                    }
                    .onDisappear { scanPhase = 0 }
                }
            }
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
