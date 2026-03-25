//
//  DocumentCanvasView.swift
//  VibePDF
//

import SwiftUI

struct DocumentCanvasView: View {
    @Environment(DocumentCoordinator.self) private var coordinator
    @State private var scanPhase: CGFloat = 0

    var body: some View {
        let settings = coordinator.settings
        let aspectRatio = Double(settings.pixelWidth) / Double(settings.pixelHeight)

        GeometryReader { geo in
            let docFrame = docRect(in: geo.size, aspectRatio: aspectRatio)

            ZStack(alignment: .topLeading) {
                // Document card
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
                    .overlay {
                        // Scanning sweep overlay
                        if coordinator.isScanningCanvas {
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
                            .offset(y: (scanPhase - 0.5) * docFrame.height * 2)
                            .onAppear {
                                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                                    scanPhase = 1
                                }
                            }
                            .onDisappear { scanPhase = 0 }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .frame(width: docFrame.width, height: docFrame.height)
                    .position(x: docFrame.midX, y: docFrame.midY)

                // Agent cursor overlay
                if let canvasPoint = coordinator.agentCursorCanvasPoint {
                    let viewPoint = canvasToView(canvasPoint, docFrame: docFrame, docSize: CGSize(
                        width: settings.pixelWidth,
                        height: settings.pixelHeight,
                    ))
                    AgentCursorView()
                        .position(
                            x: docFrame.minX + viewPoint.x,
                            y: docFrame.minY + viewPoint.y,
                        )
                }
            }
        }
        .padding(coordinator.showHistory ? 100 : 20)
        .animation(.easeOut(duration: 1.0), value: coordinator.agentCursorCanvasPoint == nil)
    }

    /// Computes the rect the document occupies within `containerSize` (aspect-fit, centered).
    private func docRect(in containerSize: CGSize, aspectRatio: Double) -> CGRect {
        let w: CGFloat
        let h: CGFloat
        let containerAspect = containerSize.width / containerSize.height
        if containerAspect > aspectRatio {
            h = containerSize.height
            w = h * aspectRatio
        } else {
            w = containerSize.width
            h = w / aspectRatio
        }
        return CGRect(
            x: (containerSize.width - w) / 2,
            y: (containerSize.height - h) / 2,
            width: w,
            height: h,
        )
    }

    /// Maps a canvas-coordinate point to a view-coordinate point within `docFrame`.
    private func canvasToView(_ point: CGPoint, docFrame: CGRect, docSize: CGSize) -> CGPoint {
        CGPoint(
            x: (point.x / docSize.width) * docFrame.width,
            y: (point.y / docSize.height) * docFrame.height,
        )
    }
}

#Preview {
    DocumentCanvasView()
        .environment(DocumentCoordinator())
}
