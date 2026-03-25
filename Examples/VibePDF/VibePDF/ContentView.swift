//
//  ContentView.swift
//  VibePDF
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(DocumentCoordinator.self) private var coordinator

    @State private var inputText = ""
    @State private var showExporter = false
    @State private var exportDocument: PDFExportDocument? = nil

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("VibePDF")
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            exportPDF()
                        } label: {
                            Image(systemName: "arrow.up.doc")
                        }
                        .disabled(!coordinator.hasScript)
                    }

                    ToolbarItem(placement: .automatic) {
                        Button {
                            coordinator.showSidebar.toggle()
                        } label: {
                            Image(systemName: "sidebar.right")
                        }
                    }
                }
                .inspector(isPresented: Bindable(coordinator).showSidebar) {
                    SettingsSidebarView()
                }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .pdf,
            defaultFilename: "document.pdf",
        ) { _ in }
    }

    @ViewBuilder
    private var mainContent: some View {
        #if canImport(AppKit)
            MainSplitView()
        #else
            ZStack {
                TabView {
                    Tab("View", systemImage: "doc.richtext") {
                        DocumentCanvasView()
                    }
                    Tab("Code", systemImage: "curlybraces") {
                        SourceEditorView()
                    }
                }
                if coordinator.showHistory {
                    ChatHistoryView()
                } else {
                    FloatingToastView()
                }
            }
        #endif
    }

    private func exportPDF() {
        guard let data = try? coordinator.exportPDF() else { return }
        exportDocument = PDFExportDocument(data: data)
        showExporter = true
    }
}

#Preview {
    ContentView()
        .environment(DocumentCoordinator())
}
