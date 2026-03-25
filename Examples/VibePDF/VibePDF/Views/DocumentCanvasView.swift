//
//  DocumentCanvasView.swift
//  VibePDF
//

import SwiftUI

struct DocumentCanvasView: View {
    @Environment(DocumentCoordinator.self) private var coordinator

    var body: some View {
        let settings = coordinator.settings
        let aspectRatio = Double(settings.pixelWidth) / Double(settings.pixelHeight)

        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                if let image = coordinator.renderedImage {
                    Image(image, scale: 1, label: Text("Document"))
                        .resizable()
                        .scaledToFit()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .padding(20)
    }
}

#Preview {
    DocumentCanvasView()
        .environment(DocumentCoordinator())
}
