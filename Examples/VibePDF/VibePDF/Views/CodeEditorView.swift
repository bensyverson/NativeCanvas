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
        var errorLine: Int?
        var highlightRange: ClosedRange<Int>?

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

        func updateNSView(_ scrollView: NSScrollView, context _: Context) {
            guard let textView = scrollView.documentView as? NSTextView else { return }
            if textView.string != text {
                textView.string = text
            }
            applyHighlights(to: textView)
        }

        private func applyHighlights(to textView: NSTextView) {
            let storage = textView.textStorage
            let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)

            // Clear existing background highlights
            storage?.removeAttribute(.backgroundColor, range: fullRange)

            // Red highlight for error line
            if let errorLine, let range = nsRange(forLine: errorLine, in: textView.string) {
                storage?.addAttribute(
                    .backgroundColor,
                    value: NSColor.systemRed.withAlphaComponent(0.25),
                    range: range,
                )
            }

            // Blue highlight for LLM-changed lines (CALayer fade handled separately)
            if let highlightRange {
                for lineNumber in highlightRange {
                    if let range = nsRange(forLine: lineNumber, in: textView.string) {
                        storage?.addAttribute(
                            .backgroundColor,
                            value: NSColor.systemBlue.withAlphaComponent(0.20),
                            range: range,
                        )
                    }
                }
            }
        }

        /// Returns the `NSRange` covering the full content of a 1-based line number
        /// (including the line terminator, for background highlight coverage).
        private func nsRange(forLine lineNumber: Int, in string: String) -> NSRange? {
            let nsString = string as NSString
            var currentLine = 1
            var result: NSRange?

            nsString.enumerateSubstrings(
                in: NSRange(location: 0, length: nsString.length),
                options: .byLines,
            ) { _, _, enclosingRange, stop in
                if currentLine == lineNumber {
                    result = enclosingRange
                    stop.pointee = true
                }
                currentLine += 1
            }

            return result
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
