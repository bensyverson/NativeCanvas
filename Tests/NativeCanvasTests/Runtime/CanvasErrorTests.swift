//
//  CanvasErrorTests.swift
//  NativeCanvasTests
//

import NativeCanvas
import Testing

struct CanvasErrorTests {
    @Test func evaluationFailedLocalizedDescriptionContainsMessage() {
        // line/column added as optional associated values; nil preserves original format
        let error = CanvasError.evaluationFailed("SyntaxError: Unexpected token", line: nil, column: nil)
        #expect(error.localizedDescription.contains("SyntaxError: Unexpected token"))
    }

    @Test func evaluationFailedWithLineNumberIncludesLineInDescription() {
        let error = CanvasError.evaluationFailed("ReferenceError: x is not defined", line: 5, column: 1)
        #expect(error.localizedDescription.contains("line 5"))
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
