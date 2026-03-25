//
//  CodeEditorView.swift
//  VibePDF
//

#if os(macOS)
    import AppKit
    import SwiftUI

    /// A plain-text code editor backed by NSTextView with typographic substitutions disabled.
    struct CodeEditorView: NSViewRepresentable {
        @Binding var text: String

        func makeNSView(context: Context) -> NSScrollView {
            let scrollView = NSTextView.scrollableTextView()
            guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

            textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticDashSubstitutionEnabled = false
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.isContinuousSpellCheckingEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.isRichText = false
            textView.allowsUndo = true
            textView.delegate = context.coordinator

            return scrollView
        }

        func updateNSView(_ scrollView: NSScrollView, context: Context) {
            guard let textView = scrollView.documentView as? NSTextView else { return }
            if textView.string != text {
                textView.string = text
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        final class Coordinator: NSObject, NSTextViewDelegate {
            var parent: CodeEditorView

            init(_ parent: CodeEditorView) {
                self.parent = parent
            }

            func textDidChange(_ notification: Notification) {
                guard let textView = notification.object as? NSTextView else { return }
                parent.text = textView.string
            }
        }
    }

    #Preview {
        CodeEditorView(text: .constant("ctx.fillStyle = \"red\";"))
            .frame(width: 400, height: 300)
    }
#endif
