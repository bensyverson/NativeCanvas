//
//  CanvasOperableTests.swift
//  VibePDFTests
//

import Testing
@testable import VibePDF

@MainActor
struct CanvasOperableTests {
    // MARK: - read_script

    @Test func readScript_returnsCurrentScript() {
        let coordinator = DocumentCoordinator()
        coordinator.jsScript = "schema = { name: 'Test' }; layers = [];"
        #expect(coordinator.readScript().contains("schema = { name: 'Test' }"))
    }

    @Test func readScript_noScript_returnsDescriptiveMessage() {
        let coordinator = DocumentCoordinator()
        let result = coordinator.readScript()
        #expect(result.lowercased().contains("no script"))
    }

    // MARK: - write_script / edit_script

    @Test func writeScript_setsScript() async {
        let coordinator = DocumentCoordinator()
        await coordinator.setScript("const schema = { name: 'Test' }; const layers = [];")
        #expect(coordinator.jsScript == "const schema = { name: 'Test' }; const layers = [];")
    }

    @Test func editScript_replacesString() async throws {
        let coordinator = DocumentCoordinator()
        await coordinator.setScript("hello world")
        try await coordinator.editScript(old: "world", new: "Swift")
        #expect(coordinator.jsScript == "hello Swift")
    }

    @Test func editScript_throwsWhenNotFound() async {
        let coordinator = DocumentCoordinator()
        await coordinator.setScript("hello world")
        await #expect(throws: (any Error).self) {
            try await coordinator.editScript(old: "notfound", new: "Swift")
        }
    }
}
