//
//  AgentSettings.swift
//  VibePDF
//

import NativeCanvas
import Observation

@Observable final class AgentSettings {
    var provider: ProviderOption = .anthropic
    var apiKey: String = ""
    var modelName: String = ""
    var docWidth: Double = 8.5
    var docHeight: Double = 11.0
    var docUnit: DocUnit = .inches

    var pixelWidth: Int {
        docUnit.toPixels(docWidth)
    }

    var pixelHeight: Int {
        docUnit.toPixels(docHeight)
    }

    var viewport: CanvasViewport {
        CanvasViewport(width: pixelWidth, height: pixelHeight)
    }
}
