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
    var renderErrorLine: Int?
    var scriptHighlight: ScriptHighlight?

    struct ScriptHighlight: Sendable {
        let lineRange: ClosedRange<Int>
    }

    // MARK: - Chat State

    var messages: [ChatMessage] = []
    var lastConversation: Conversation?
    var isAgentRunning: Bool = false

    // MARK: - UI State

    var showHistory: Bool = false
    var showSidebar: Bool = false
    var isScanningCanvas: Bool = false
    var isScanningScript: Bool = false
    var agentCursorCanvasPoint: CGPoint?

    /// True while a `write_script` tool call's arguments are being streamed in.
    /// Render errors are suppressed during this phase because the JS is incomplete.
    var isStreamingScript: Bool = false

    // MARK: - Settings

    var settings: AgentSettings = .init()

    // MARK: - Private

    private var operative: Operative?
    private var sendTask: Task<Void, Never>?

    private var systemPrompt: String {
        """
        You are an expert visual designer and page layout specialist. You create documents \
        using JavaScript and the Canvas 2D API.

        The ONLY top-level variable you need to define is `layers`, an array of `{ name: "...", render(ctx, params, scene) { ... } }` objects (see below for an example). All your drawing code will go into the render() functions.

        You will be passed an object, `scene`, which contains the view dimensions in `scene.viewport.width` and `scene.viewport.height`.

        In this document 1px = 1pt, at 72 DPI.

        The `nc` standard library is always available:

        Interpolation / easing:
          nc.lerp(a, b, t)
          nc.clamp(v, min, max)
          nc.map(v, inMin, inMax, outMin, outMax) // remap one range to another
          nc.smoothstep(edge0, edge1, t)
          nc.easeIn(t) / easeOut(t) / easeInOut(t)
          nc.steps(t, n?) // stepped / quantized interpolation

        Color:
          nc.rgba(r, g, b, a?)
          nc.lerpColor(a, b, t)
          nc.hexToRgb(hex) // parse hex → {r, g, b, a}

        Math:
          nc.random(seed) // deterministic pseudo-random [0, 1)
          nc.noise(x, y, seed?)
          nc.degToRad(d) / radToDeg(r)

        Drawing:
          nc.roundRect(ctx, x, y, w, h, r) // call fill/stroke after
          nc.drawTextWithShadow(ctx, text, x, y, opts)

        Layout:
          nc.safeArea(viewport) // includes margins
          nc.grid(viewport, cols, rows) // → [{x, y, width, height}] grid cells

        Typography (use instead of ctx.measureText):
          nc.measureText(text, font) // → {width, height}; font is a CSS string, e.g. 'bold 32px "Georgia"'
          nc.wrapText(text, maxWidth, font) // → string[] of wrapped lines; font is a CSS string
          nc.fitText(text, maxWidth, fontFamily, style?) // → largest font size (px) that fits; style is optional, e.g. "bold" or "italic bold"

        IMPORTANT — ctx.fillText maxWidth pitfall:
        The 4th argument to ctx.fillText(text, x, y, maxWidth) is a horizontal-only squish — it compresses
        glyphs sideways without reducing height, which looks ugly. Avoid it for body text and headlines.
        Instead, use nc.fitText() to find the right font size, or nc.wrapText() to wrap long lines.

        Example script:
        ```javascript
        const margin = 48;
        layers = [
          {
            name: "headline",
            render(ctx, params, scene) {
              const text = "Here's where a headline goes.";
              const maxWidth = scene.viewport.width - margin * 2;
              const size = nc.fitText(text, maxWidth, "Georgia", "bold");
              ctx.font = `bold ${size}px "Georgia"`;
              ctx.fillStyle = "#1a1a1a";
              ctx.fillText(text, margin, margin + size);
            }
          },
          {
            name: "body",
            render(ctx, params, scene) {
              const maxWidth = scene.viewport.width - margin * 2;
              const size = 14, lineHeight = size * 1.6;
              ctx.font = `${size}px "Georgia"`;
              ctx.fillStyle = "#444444";
              const lines = nc.wrapText("Body copy goes here. It always wraps to fit the column no matter how long it ends up being.", maxWidth, ctx.font);
              lines.forEach((line, i) => ctx.fillText(line, margin, 120 + (i * lineHeight)));
            }
          }
        ];
        ```

        Workflow:
        1. Use read_script before making changes
        2. Use write_script to create or fully replace a script.
        3. Use edit_script for targeted changes (find old string, replace with new). When possible, edit rather than creating a brand new script.
        4. Always use view_canvas (if available) to visually verify your changes.

        Style notes:
        - 1.2x font size is a good starting point for line spacing
        - As a general rule, make your headline and body copy different font styles (serif vs sans-serif)

        Important notes:
        - Keep scripts clean and well-structured. Use meaningful layer names.
        - Be careful to escape any quotes (") in non-templated string literals.
        - Pay CLOSE attention to typography. ALWAYS make sure your text doesn't overlap, and isn't cut off, unless that is the desired effect. Look carefully!
        - Do not use Markdown lists or tables in your messages!
        - Keep your messages to the user friendly and SHORT; try to stay under 20 words. Don't just recap what you did.
        - DO NOT create the canvas or context objects. Our own ctx will be combined with your `layers` array to render the document.
        - Feel free to create your document iteratively; you can create a layer or two, render the result, then edit or add layers until you're satisfied.
        - Before deciding that you're done, use view_canvas to look at your work. Is there anything you could improve? If so, give it one more pass.

        Document size: \(settings.pixelWidth) x \(settings.pixelHeight) pt
        """
    }

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
        let config: Operator.ConversationConfiguration = settings.provider.requiresModelName && !settings.modelName.isEmpty
            ? Operator.ConversationConfiguration(model: Operator.ModelName(rawValue: settings.modelName))
            : Operator.ConversationConfiguration(modelType: settings.modelType)

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
        // Set state synchronously so SwiftUI shows the user message and
        // thinking indicator immediately, before any async work begins.
        isAgentRunning = true
        messages.append(ChatMessage(id: UUID(), role: .user, text: text))
        sendTask = Task { await _send(text) }
    }

    func stop() {
        sendTask?.cancel()
        sendTask = nil
        isAgentRunning = false
    }

    private func _send(_ text: String) async {
        guard let operative else {
            appendError("Agent not configured. Check your provider settings.")
            isAgentRunning = false
            sendTask = nil
            return
        }
        var currentAgentMessageID: UUID? = nil

        // Accumulates streaming tool call arguments per tool-call index.
        var toolCallNames: [Int: String] = [:]
        var toolCallArgs: [Int: String] = [:]
        // Throttle script streaming updates to avoid overwhelming SwiftUI.
        var lastStreamUpdate: ContinuousClock.Instant = .now
        let streamInterval: Duration = .milliseconds(250)

        defer {
            // Always finalize any in-flight streaming message so the UI cleans up.
            if let agentID = currentAgentMessageID,
               let idx = messages.firstIndex(where: { $0.id == agentID })
            {
                messages[idx].isStreaming = false
            }
            isStreamingScript = false
            // If cancelled (by stop() or a new send()), the caller already
            // owns isAgentRunning/sendTask — don't overwrite their state.
            if !Task.isCancelled {
                isAgentRunning = false
                sendTask = nil
            }
        }

        let stream: OperationStream = if let convo = lastConversation {
            operative.run(text, continuing: convo)
        } else {
            operative.run(text)
        }

        do {
            for try await operation in stream {
                guard !Task.isCancelled else { break }
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

                case let .toolCallDelta(delta):
                    // Track tool name from the first delta; accumulate argument fragments.
                    if let name = delta.name {
                        toolCallNames[delta.index] = name
                    }
                    toolCallArgs[delta.index, default: ""] += delta.argumentsFragment

                    // Stream the script into the editor, throttled to ~10 fps.
                    if toolCallNames[delta.index] == "write_script" {
                        if !isStreamingScript {
                            isStreamingScript = true
                            lastStreamUpdate = .now
                            // Finalize any in-flight agent text message.
                            if let agentID = currentAgentMessageID,
                               let idx = messages.firstIndex(where: { $0.id == agentID })
                            {
                                messages[idx].isStreaming = false
                            }
                            currentAgentMessageID = nil
                            messages.append(ChatMessage(id: UUID(), role: .toolCall, text: "write_script", toolName: "write_script"))
                        }
                        let now: ContinuousClock.Instant = .now
                        if now - lastStreamUpdate >= streamInterval,
                           let partial = Self.extractPartialScript(from: toolCallArgs[delta.index, default: ""])
                        {
                            lastStreamUpdate = now
                            streamScript(partial)
                        }
                    }

                case let .toolsRequested(requests):
                    // Script streaming is done — the full tool call has arrived.
                    if isStreamingScript {
                        isStreamingScript = false
                        // Re-render with the final script to clear any suppressed errors.
                        rerender()
                    }
                    toolCallNames.removeAll()
                    toolCallArgs.removeAll()

                    if let agentID = currentAgentMessageID,
                       let idx = messages.firstIndex(where: { $0.id == agentID })
                    {
                        messages[idx].isStreaming = false
                    }
                    currentAgentMessageID = nil
                    for req in requests {
                        // Don't duplicate the toolCall message if we already added it during streaming.
                        if req.name == "write_script", messages.last?.toolName == "write_script" {
                            continue
                        }
                        messages.append(ChatMessage(id: UUID(), role: .toolCall, text: req.name, toolName: req.name))
                    }

                case let .toolFailed(req, error):
                    messages.append(ChatMessage(
                        id: UUID(),
                        role: .error,
                        text: "Tool \(req.name) failed: \(error.message)",
                    ))

                case let .completed(result):
                    lastConversation = result.conversation
                    if let agentID = currentAgentMessageID,
                       let idx = messages.firstIndex(where: { $0.id == agentID })
                    {
                        messages[idx].isStreaming = false
                    }

                case let .stopped(reason):
                    if let agentID = currentAgentMessageID,
                       let idx = messages.firstIndex(where: { $0.id == agentID })
                    {
                        messages[idx].isStreaming = false
                    }
                    appendError(stopReasonMessage(reason))

                default:
                    break
                }
            }
        } catch {
            appendError(error.localizedDescription)
        }
    }

    /// Extracts the partial value of the `"script"` key from a streaming JSON
    /// arguments string. The tool's arguments look like `{"script": "..."}`.
    /// We find the opening quote after the key and JSON-decode the partial
    /// string value (handling `\n`, `\"`, `\\`, etc.).
    private static func extractPartialScript(from json: String) -> String? {
        // Find the start of the script value after `"script":`
        let pattern = #/"script"\s*:\s*"/#
        guard let match = json.firstMatch(of: pattern) else { return nil }
        let valueStart = match.range.upperBound

        // Everything from the opening quote to the end is the partial JSON string value.
        // It may be unterminated (no closing quote yet), so we can't use JSONDecoder.
        // Instead, manually unescape JSON string escapes.
        let raw = String(json[valueStart...])
        return unescapeJSONString(raw)
    }

    /// Unescapes a partial JSON string body (without surrounding quotes).
    /// Handles `\\`, `\"`, `\/`, `\n`, `\r`, `\t`, `\uXXXX`.
    private static func unescapeJSONString(_ raw: String) -> String {
        var result = ""
        result.reserveCapacity(raw.count)
        var iter = raw.makeIterator()

        while let ch = iter.next() {
            if ch == "\\" {
                guard let esc = iter.next() else {
                    // Trailing backslash — escape sequence is still being streamed.
                    break
                }
                switch esc {
                case "n": result.append("\n")
                case "r": result.append("\r")
                case "t": result.append("\t")
                case "\"": result.append("\"")
                case "\\": result.append("\\")
                case "/": result.append("/")
                case "u":
                    // \uXXXX — read 4 hex digits
                    var hex = ""
                    for _ in 0 ..< 4 {
                        guard let h = iter.next() else { return result }
                        hex.append(h)
                    }
                    if let code = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(code) {
                        result.append(Character(scalar))
                    }
                default:
                    // Unknown escape — append as-is
                    result.append("\\")
                    result.append(esc)
                }
            } else if ch == "\"" {
                // Closing quote of the JSON string value — stop here.
                break
            } else {
                result.append(ch)
            }
        }

        return result
    }

    private func appendError(_ text: String) {
        messages.append(ChatMessage(id: UUID(), role: .error, text: text))
    }

    private func stopReasonMessage(_ reason: StopReason) -> String {
        switch reason {
        case .turnLimitReached:
            "Agent stopped: turn limit reached."
        case .tokenBudgetExhausted:
            "Agent stopped: token budget exhausted."
        case .timeout:
            "Agent stopped: timed out."
        case let .explicitStop(reason):
            reason
        }
    }

    // MARK: - Script Management

    // MARK: - Visual Feedback

    func beginScanningCanvas() {
        isScanningCanvas = true
    }

    func endScanningCanvas() {
        isScanningCanvas = false
    }

    func beginScanningScript() {
        isScanningScript = true
    }

    func endScanningScript() {
        isScanningScript = false
    }

    func updateCursor(from code: String) {
        // Parse the first X,Y coordinate pair from canvas API calls
        let pattern = #/(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)/#
        if let match = code.firstMatch(of: pattern),
           let x = Double(match.1),
           let y = Double(match.2)
        {
            agentCursorCanvasPoint = CGPoint(x: x, y: y)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                agentCursorCanvasPoint = nil
            }
        }
    }

    // MARK: - Script Reading

    func readScript() -> String {
        jsScript ?? "(no script loaded)"
    }

    // MARK: - Script Writing

    @discardableResult
    func setScript(_ script: String) async -> String? {
        let oldScript = jsScript
        jsScript = script
        rerender()
        setHighlight(diffing: oldScript, against: script)
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
        setHighlight(forInsertedText: new, in: source)
        return renderError
    }

    private func setHighlight(diffing old: String?, against new: String) {
        let oldLines = (old ?? "").components(separatedBy: "\n")
        let newLines = new.components(separatedBy: "\n")
        var firstChanged: Int?
        var lastChanged: Int?
        for (index, newLine) in newLines.enumerated() {
            let oldLine = index < oldLines.count ? oldLines[index] : nil
            if newLine != oldLine {
                if firstChanged == nil { firstChanged = index + 1 }
                lastChanged = index + 1
            }
        }
        guard let first = firstChanged, let last = lastChanged else { return }
        scheduleHighlight(ScriptHighlight(lineRange: first ... last))
    }

    private func setHighlight(forInsertedText inserted: String, in source: String) {
        // Find the line range where `inserted` appears in the updated source
        guard let matchRange = source.range(of: inserted) else { return }
        let prefix = String(source[source.startIndex ..< matchRange.lowerBound])
        let firstLine = prefix.components(separatedBy: "\n").count
        let insertedLineCount = inserted.components(separatedBy: "\n").count
        let lastLine = max(firstLine, firstLine + insertedLineCount - 1)
        scheduleHighlight(ScriptHighlight(lineRange: firstLine ... lastLine))
    }

    private func scheduleHighlight(_ highlight: ScriptHighlight) {
        scriptHighlight = highlight
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            scriptHighlight = nil
        }
    }

    /// Sets the script from a streaming tool call delta without highlighting
    /// or clearing previous render state. Render errors are suppressed because
    /// the JS is still incomplete.
    func streamScript(_ partialScript: String) {
        jsScript = partialScript
        rerender()
    }

    func rerender() {
        guard let source = jsScript else {
            renderedImage = nil
            renderError = nil
            renderErrorLine = nil
            return
        }
        do {
            renderedImage = try CanvasRenderer.render(source: source, viewport: settings.viewport, scale: 2)
            renderError = nil
            renderErrorLine = nil
        } catch let CanvasError.evaluationFailed(message, line: line, column: _) {
            // Suppress errors while the script is still being streamed in —
            // the JS is incomplete and will fail to parse until finished.
            guard !isStreamingScript else { return }
            renderError = message
            renderErrorLine = line
        } catch {
            guard !isStreamingScript else { return }
            renderError = error.localizedDescription
            renderErrorLine = nil
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
