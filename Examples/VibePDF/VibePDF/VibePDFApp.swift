//
//  VibePDFApp.swift
//  VibePDF
//

import SwiftUI

@main
struct VibePDFApp: App {
    @State private var coordinator = DocumentCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(coordinator)
                .task { coordinator.buildOperative() }
        }
    }
}
