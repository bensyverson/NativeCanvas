//
//  AgentSettingsTests.swift
//  VibePDFTests
//

import Testing
@testable import VibePDF

struct AgentSettingsTests {
    @Test func pxUnit_isPassthrough() {
        #expect(DocUnit.px.toPixels(100) == 100)
    }

    @Test func inchesUnit_at72dpi() {
        // 8.5" × 72 DPI = 612 px
        #expect(DocUnit.inches.toPixels(8.5) == 612)
    }

    @Test func mmUnit_at72dpi() {
        // 210mm × 72 / 25.4 ≈ 595 px (A4 width)
        #expect(DocUnit.mm.toPixels(210) == 595)
    }

    @Test func defaultSettings_isLetterSize() {
        let settings = AgentSettings()
        #expect(settings.pixelWidth == 612)
        #expect(settings.pixelHeight == 792)
    }
}
