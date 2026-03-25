//
//  DocumentCoordinator.swift
//  VibePDF
//

import CoreGraphics
import Foundation
import NativeCanvas
import Observation
import Operator

@Observable final class DocumentCoordinator {
    // MARK: - Document State

    var jsScript: String?
    var renderedImage: CGImage?
    var renderError: String?

    // MARK: - Chat State

    var messages: [ChatMessage] = []
    var lastConversation: Conversation?
    var isAgentRunning: Bool = false

    // MARK: - UI State

    var showHistory: Bool = false
    var showSidebar: Bool = false

    // MARK: - Settings

    var settings: AgentSettings = .init()

    // MARK: - Private

    private var operative: Operative?
    private var sendTask: Task<Void, Never>?

    private let systemPrompt = """
    You are a creative document-generation assistant. You render documents \
    by writing JavaScript scripts using the Canvas 2D API.

    Every script must export two globals:
    - `schema`: an object with at least `{ name: "..." }` and optional `params`
    - `layers`: an array of `{ name: "...", render(ctx, params, scene) { ... } }` objects

    Use `scene.viewport.width` and `scene.viewport.height` for document dimensions.
    The `nc` standard library is available: nc.lerp(), nc.rgba(), nc.pt(), nc.roundRect(), etc.

    Example script:
    ```javascript
    schema = { name: "Red Rectangle" };
    layers = [
      {
        name: "background",
        render(ctx, params, scene) {
          ctx.fillStyle = "#808080";
          ctx.fillRect(0, 0, scene.viewport.width, scene.viewport.height);
        }
      },
      {
        name: "rectangle",
        render(ctx, params, scene) {
          const w = scene.viewport.width, h = scene.viewport.height;
          ctx.fillStyle = "red";
          ctx.fillRect(w * 0.25, h * 0.25, w * 0.5, h * 0.5);
        }
      }
    ];
    ```

    Workflow:
    1. Use write_script to create or fully replace a script.
    2. Use edit_script for targeted changes (find old string, replace with new).
    3. Use view_canvas to visually verify results before responding to the user.

    Keep scripts clean and well-structured. Use meaningful layer names.
    """

    // MARK: - Computed

    var hasScript: Bool {
        jsScript != nil
    }

    // MARK: - Operative

    func buildOperative() {
        let supportsVision = settings.provider.supportsVision(modelName: settings.modelName)
        guard let operable = try? CanvasOperable(coordinator: self, supportsVision: supportsVision) else { return }

        #if canImport(FoundationModels)
            if settings.provider == .appleIntelligence, #available(macOS 26.0, iOS 26.0, *) {
                operative = try? Operative(
                    name: "VibePDF Agent",
                    description: "Creates PDF documents using NativeCanvas",
                    systemPrompt: systemPrompt,
                    tools: [operable],
                    budget: Budget(maxTurns: 20),
                )
                return
            }
        #endif

        let provider = settings.provider.resolveProvider(apiKey: settings.apiKey)
        let config: Operator.ConversationConfiguration = settings.modelName.isEmpty
            ? Operator.ConversationConfiguration(
                modelType: .fast,
                inference: .reasoning,
                reasoningEffort: .medium,
            )
            : Operator.ConversationConfiguration(
                model: Operator.ModelName(rawValue: settings.modelName),
            )

        operative = try? Operative(
            name: "VibePDF Agent",
            description: "Creates documents using NativeCanvas",
            provider: provider,
            systemPrompt: systemPrompt,
            tools: [operable],
            budget: Budget(maxTurns: 20),
            configuration: config,
        )
    }

    // MARK: - Messaging

    func send(_ text: String) {
        sendTask?.cancel()
        sendTask = Task { await _send(text) }
    }

    func stop() {
        sendTask?.cancel()
        sendTask = nil
        isAgentRunning = false
    }

    private func _send(_ text: String) async {
        guard let operative else { return }
        isAgentRunning = true
        var currentAgentMessageID: UUID? = nil
        defer {
            // Always finalize any in-flight streaming message so the UI cleans up.
            if let agentID = currentAgentMessageID,
               let idx = messages.firstIndex(where: { $0.id == agentID })
            {
                messages[idx].isStreaming = false
            }
            // If cancelled (by stop() or a new send()), the caller already
            // owns isAgentRunning/sendTask — don't overwrite their state.
            if !Task.isCancelled {
                isAgentRunning = false
                sendTask = nil
            }
        }

        messages.append(ChatMessage(id: UUID(), role: .user, text: text))

        let stream: OperationStream = if let convo = lastConversation {
            operative.run(text, continuing: convo)
        } else {
            operative.run(text)
        }

        for await operation in stream {
            switch operation {
            case let .text(chunk):
                if let agentID = currentAgentMessageID,
                   let idx = messages.firstIndex(where: { $0.id == agentID })
                {
                    messages[idx].text += chunk
                } else {
                    let msg = ChatMessage(id: UUID(), role: .agent, text: chunk, isStreaming: true)
                    messages.append(msg)
                    currentAgentMessageID = msg.id
                }

            case let .toolsRequested(requests):
                if let agentID = currentAgentMessageID,
                   let idx = messages.firstIndex(where: { $0.id == agentID })
                {
                    messages[idx].isStreaming = false
                }
                currentAgentMessageID = nil
                for req in requests {
                    messages.append(ChatMessage(id: UUID(), role: .toolCall, text: req.name, toolName: req.name))
                }

            case let .toolFailed(req, error):
                messages.append(ChatMessage(
                    id: UUID(),
                    role: .system,
                    text: "Tool \(req.name) failed: \(error.message)",
                ))

            case let .completed(result):
                lastConversation = result.conversation
                if let agentID = currentAgentMessageID,
                   let idx = messages.firstIndex(where: { $0.id == agentID })
                {
                    messages[idx].isStreaming = false
                }

            case .stopped:
                if let agentID = currentAgentMessageID,
                   let idx = messages.firstIndex(where: { $0.id == agentID })
                {
                    messages[idx].isStreaming = false
                }

            default:
                break
            }
        }
    }

    // MARK: - Script Management

    @discardableResult
    func setScript(_ script: String) async -> String? {
        jsScript = script
        rerender()
        return renderError
    }

    @discardableResult
    func editScript(old: String, new: String) async throws -> String? {
        guard var source = jsScript else { throw EditError.noScript }
        guard source.contains(old) else { throw EditError.stringNotFound }
        if let range = source.range(of: old) {
            source.replaceSubrange(range, with: new)
        }
        jsScript = source
        rerender()
        return renderError
    }

    func rerender() {
        guard let source = jsScript else {
            renderedImage = nil
            return
        }
        do {
            renderedImage = try CanvasRenderer.render(source: source, viewport: settings.viewport)
            renderError = nil
        } catch {
            renderError = error.localizedDescription
        }
    }

    // MARK: - Export

    func exportPDF() throws -> Data {
        guard let source = jsScript else { throw ExportError.noScript }
        let vp = settings.viewport
        var mediaBox = CGRect(x: 0, y: 0, width: vp.width, height: vp.height)
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else { throw ExportError.contextCreationFailed }
        ctx.beginPDFPage(nil)
        try CanvasRenderer.render(source: source, scene: NoScene(), into: ctx, viewport: vp)
        ctx.endPDFPage()
        ctx.closePDF()
        return data as Data
    }

    // MARK: - Errors

    enum EditError: LocalizedError {
        case noScript
        case stringNotFound

        var errorDescription: String? {
            switch self {
            case .noScript: "No script is currently loaded."
            case .stringNotFound: "The specified string was not found in the script."
            }
        }
    }

    enum ExportError: LocalizedError {
        case noScript
        case contextCreationFailed

        var errorDescription: String? {
            switch self {
            case .noScript: "No script is currently loaded."
            case .contextCreationFailed: "Failed to create PDF rendering context."
            }
        }
    }
}
