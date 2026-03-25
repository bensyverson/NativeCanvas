//
//  CanvasErrorTests.swift
//  NativeCanvasTests
//

import NativeCanvas
import Testing

struct CanvasErrorTests {
    @Test func evaluationFailedLocalizedDescriptionContainsMessage() {
        let error = CanvasError.evaluationFailed("SyntaxError: Unexpected token")
        #expect(error.localizedDescription.contains("SyntaxError: Unexpected token"))
    }

    @Test func missingExportLocalizedDescriptionContainsExportName() {
        let error = CanvasError.missingExport("layers")
        #expect(error.localizedDescription.contains("layers"))
    }

    @Test func invalidLayersLocalizedDescriptionIsReadable() {
        let error = CanvasError.invalidLayers
        #expect(!error.localizedDescription.hasPrefix("The operation couldn't be completed."))
    }
}
