//
//  AgentSettingsTests.swift
//  VibePDFTests
//

import Foundation
import Testing
@testable import VibePDF

struct AgentSettingsTests {
    // MARK: - Keychain-backed API keys

    @Test func apiKey_persistsPerProvider() {
        let settings = AgentSettings()
        // Set key for anthropic
        settings.provider = .anthropic
        settings.apiKey = "test-anthropic-key-\(UUID().uuidString)"
        let savedKey = settings.apiKey

        // Switch to a different provider
        settings.provider = .openAI
        #expect(settings.apiKey.isEmpty || settings.apiKey != savedKey, "Different provider should not share key")

        // Switch back — key should be restored
        settings.provider = .anthropic
        #expect(settings.apiKey == savedKey, "Switching back to original provider should restore the key")

        // Cleanup
        settings.apiKey = ""
    }

    @Test func hasAPIKey_falseWhenProviderRequiresKeyAndKeyIsEmpty() {
        let settings = AgentSettings()
        settings.provider = .anthropic
        settings.apiKey = ""
        #expect(settings.hasAPIKey == false)
    }

    @Test func hasAPIKey_trueWhenProviderDoesNotRequireKey() {
        let settings = AgentSettings()
        settings.provider = .lmStudio
        #expect(settings.hasAPIKey == true)
    }

    // MARK: - Document size

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
