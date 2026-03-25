//
//  CanvasOperable.swift
//  VibePDF
//

import CoreGraphics
import Foundation
import ImageIO
import NativeCanvas
import Operator

#if canImport(FoundationModels)
    import FoundationModels
#endif

// MARK: - Tool Inputs

#if canImport(FoundationModels)
    @Generable
#endif
struct WriteScriptInput: ToolInput {
    #if canImport(FoundationModels)
        @Guide(description: "The complete NativeCanvas JavaScript source to write. Must export `schema` and `layers` globals.")
    #endif
    var script: String

    static let paramDescriptions: [String: String] = [
        "script": "The complete NativeCanvas JavaScript source to write. Must export `schema` and `layers` globals.",
    ]
}

#if canImport(FoundationModels)
    @Generable
#endif
struct EditScriptInput: ToolInput {
    #if canImport(FoundationModels)
        @Guide(description: "The exact substring to find and replace (first occurrence only).")
    #endif
    var old_string: String

    #if canImport(FoundationModels)
        @Guide(description: "The replacement string.")
    #endif
    var new_string: String

    static let paramDescriptions: [String: String] = [
        "old_string": "The exact substring to find and replace (first occurrence only).",
        "new_string": "The replacement string.",
    ]
}

// Dummy inputs for no-argument tools so Apple Intelligence can invoke them.
#if canImport(FoundationModels)
    @Generable
    struct ReadScriptInput: ToolInput {
        @Guide(description: "Ignored — reads the current script unconditionally.")
        var ignored: String?

        static var paramDescriptions: [String: String] {
            ["ignored": "Ignored"]
        }
    }

    @Generable
    struct ViewCanvasInput: ToolInput {
        @Guide(description: "Ignored — renders the current canvas unconditionally.")
        var ignored: String?

        static var paramDescriptions: [String: String] {
            ["ignored": "Ignored"]
        }
    }
#endif

// MARK: - CanvasOperable

final class CanvasOperable: Operable {
    let toolGroup: ToolGroup

    init(coordinator: DocumentCoordinator, supportsVision: Bool) throws {
        let writeScriptTool = try Tool(
            name: "write_script",
            description: "Write or fully replace the NativeCanvas JavaScript script for the document.",
            input: WriteScriptInput.self,
        ) { [weak coordinator] input in
            guard let coordinator else {
                return ToolOutput("Error: coordinator unavailable.")
            }
            let renderError = await coordinator.setScript(input.script)
            await coordinator.updateCursor(from: input.script)
            if let renderError {
                return ToolOutput("Render error: \(renderError)")
            }
            return ToolOutput("Script written successfully.")
        }

        let editScriptTool = try Tool(
            name: "edit_script",
            description: "Make a targeted edit to the current script by replacing the first occurrence of old_string with new_string.",
            input: EditScriptInput.self,
        ) { [weak coordinator] input in
            guard let coordinator else {
                return ToolOutput("Error: coordinator unavailable.")
            }
            do {
                let renderError = try await coordinator.editScript(old: input.old_string, new: input.new_string)
                await coordinator.updateCursor(from: input.new_string)
                if let renderError {
                    return ToolOutput("Render error: \(renderError)")
                }
                return ToolOutput("Edit applied successfully.")
            } catch {
                return ToolOutput("Error: \(error.localizedDescription)")
            }
        }

        #if canImport(FoundationModels)
            let readScriptTool = try Tool(
                name: "read_script",
                description: "Read the current NativeCanvas JavaScript script. Use this when the user says they have pasted or typed a script and you need to see it.",
                input: ReadScriptInput.self,
            ) { [weak coordinator] _ in
                guard let coordinator else {
                    return ToolOutput("Error: coordinator unavailable.")
                }
                await coordinator.beginScanningScript()
                let script = await coordinator.readScript()
                try? await Task.sleep(for: .milliseconds(600))
                await coordinator.endScanningScript()
                return ToolOutput(script)
            }
        #else
            let readScriptTool = Tool(
                name: "read_script",
                description: "Read the current NativeCanvas JavaScript script. Use this when the user says they have pasted or typed a script and you need to see it.",
            ) { [weak coordinator] in
                guard let coordinator else {
                    return ToolOutput("Error: coordinator unavailable.")
                }
                await coordinator.beginScanningScript()
                let script = await coordinator.readScript()
                try? await Task.sleep(for: .milliseconds(600))
                await coordinator.endScanningScript()
                return ToolOutput(script)
            }
        #endif

        var tools: [any ToolProvider] = [readScriptTool, writeScriptTool, editScriptTool]

        if supportsVision {
            #if canImport(FoundationModels)
                let viewCanvasTool = try Tool(
                    name: "view_canvas",
                    description: "Render the current script and view the result as an image to verify output.",
                    input: ViewCanvasInput.self,
                ) { [weak coordinator] _ in
                    await Self.viewCanvas(coordinator: coordinator)
                }
            #else
                let viewCanvasTool = Tool(
                    name: "view_canvas",
                    description: "Render the current script and view the result as an image to verify output.",
                ) { [weak coordinator] in
                    await Self.viewCanvas(coordinator: coordinator)
                }
            #endif
            tools.append(viewCanvasTool)
        }

        toolGroup = ToolGroup(name: "Canvas", tools: tools)
    }

    private static func viewCanvas(coordinator: DocumentCoordinator?) async -> ToolOutput {
        guard let coordinator else {
            return ToolOutput("Error: coordinator unavailable.")
        }
        guard let source = await coordinator.jsScript else {
            return ToolOutput("No script loaded yet.")
        }
        let viewport = await coordinator.settings.viewport
        await coordinator.beginScanningCanvas()
        // Yield briefly so SwiftUI can render the scan overlay before the
        // synchronous render occupies the thread.
        try? await Task.sleep(for: .milliseconds(50))
        do {
            let image = try CanvasRenderer.render(source: source, viewport: viewport)
            // Keep the animation visible for a minimum duration.
            try? await Task.sleep(for: .milliseconds(400))
            await coordinator.endScanningCanvas()
            guard let data = Self.pngData(from: image) else {
                return ToolOutput("Failed to encode canvas image.")
            }
            return ToolOutput([Operator.ContentPart.image(data: data, mediaType: "image/png", filename: "canvas.png")])
        } catch {
            await coordinator.endScanningCanvas()
            return ToolOutput("Render error: \(error.localizedDescription)")
        }
    }

    private static func pngData(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }
}
