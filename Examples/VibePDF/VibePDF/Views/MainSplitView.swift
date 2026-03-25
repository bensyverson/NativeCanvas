//
//  MainSplitView.swift
//  VibePDF
//

#if os(macOS)
    import AppKit
    import SwiftUI

    /// Two-column horizontal split view backed by NSSplitViewController.
    ///
    /// Uses `preferredThicknessFraction` for the trailing column's initial width on
    /// first launch, and `autosaveName` to persist the divider position across launches.
    struct MainSplitView: NSViewControllerRepresentable {
        @Environment(DocumentCoordinator.self) private var coordinator

        func makeNSViewController(context _: Context) -> NSSplitViewController {
            let vc = NSSplitViewController()
            vc.splitView.isVertical = true
            vc.splitView.dividerStyle = .thin
            vc.splitView.autosaveName = "VibePDF.MainSplit"

            let leadingVC = NSHostingController(rootView: leadingView(coordinator: coordinator))
            let leadingItem = NSSplitViewItem(viewController: leadingVC)
            leadingItem.minimumThickness = 300
            leadingItem.canCollapse = false

            let trailingVC = NSHostingController(rootView: trailingView(coordinator: coordinator))

            let trailingItem = NSSplitViewItem(viewController: trailingVC)
            trailingItem.minimumThickness = 180
            trailingItem.preferredThicknessFraction = 0.28
            trailingItem.canCollapse = false

            vc.addSplitViewItem(leadingItem)
            vc.addSplitViewItem(trailingItem)

            return vc
        }

        func updateNSViewController(_ vc: NSSplitViewController, context _: Context) {
            (vc.splitViewItems[0].viewController as? NSHostingController<LeadingView>)?.rootView =
                leadingView(coordinator: coordinator)
            (vc.splitViewItems[1].viewController as? NSHostingController<TrailingView>)?.rootView =
                trailingView(coordinator: coordinator)
        }

        // MARK: - Column Views

        private func leadingView(coordinator: DocumentCoordinator) -> LeadingView {
            LeadingView(coordinator: coordinator)
        }

        private func trailingView(coordinator: DocumentCoordinator) -> TrailingView {
            TrailingView(coordinator: coordinator)
        }
    }

    /// The canvas + chat/toast overlay, passed the coordinator explicitly so
    /// it can be embedded in an NSHostingController outside the SwiftUI tree.
    private struct LeadingView: View {
        var coordinator: DocumentCoordinator
        @State private var inputText = ""

        var body: some View {
            ZStack(alignment: .center) {
                DocumentCanvasView()

                if coordinator.showHistory {
                    ChatHistoryView()
                } else {
                    FloatingToastView()
                }
            }.safeAreaInset(edge: .bottom) {
                ChatInputBar(inputText: $inputText)
            }
            .environment(coordinator)
        }
    }

    private struct TrailingView: View {
        var coordinator: DocumentCoordinator

        var body: some View {
            SourceEditorView()
                .environment(coordinator)
        }
    }
#endif
