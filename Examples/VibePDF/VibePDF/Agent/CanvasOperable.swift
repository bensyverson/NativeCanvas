//
//  CanvasOperable.swift
//  VibePDF
//

import CoreGraphics
import Foundation
import ImageIO
import NativeCanvas
import Operator

// MARK: - Tool Inputs

struct WriteScriptInput: ToolInput {
    let script: String

    static let paramDescriptions: [String: String] = [
        "script": "The complete NativeCanvas JavaScript source to write. Must export `schema` and `layers` globals.",
    ]
}

struct EditScriptInput: ToolInput {
    let old_string: String
    let new_string: String

    static let paramDescriptions: [String: String] = [
        "old_string": "The exact substring to find and replace (first occurrence only).",
        "new_string": "The replacement string.",
    ]
}

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
                if let renderError {
                    return ToolOutput("Render error: \(renderError)")
                }
                return ToolOutput("Edit applied successfully.")
            } catch {
                return ToolOutput("Error: \(error.localizedDescription)")
            }
        }

        var tools: [any ToolProvider] = [writeScriptTool, editScriptTool]

        if supportsVision {
            let viewCanvasTool = Tool(
                name: "view_canvas",
                description: "Render the current script and view the result as an image to verify output.",
            ) { [weak coordinator] in
                guard let coordinator else {
                    return ToolOutput("Error: coordinator unavailable.")
                }
                guard let source = await coordinator.jsScript else {
                    return ToolOutput("No script loaded yet.")
                }
                let viewport = await coordinator.settings.viewport
                do {
                    let image = try CanvasRenderer.render(source: source, viewport: viewport)
                    guard let data = Self.pngData(from: image) else {
                        return ToolOutput("Failed to encode canvas image.")
                    }
                    return ToolOutput([Operator.ContentPart.image(data: data, mediaType: "image/png", filename: "canvas.png")])
                } catch {
                    return ToolOutput("Render error: \(error.localizedDescription)")
                }
            }
            tools.append(viewCanvasTool)
        }

        toolGroup = ToolGroup(name: "Canvas", tools: tools)
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
