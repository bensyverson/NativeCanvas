//
//  CanvasSourcePreprocessor.swift
//  NativeCanvas
//

import Foundation

/// Strips ES module syntax from template source so it evaluates in JSCore's global scope.
///
/// JSCore doesn't support ES modules. This preprocessor transforms `export` declarations
/// into plain variable/function declarations that create accessible globals.
///
/// - `export const` → `var` (because JSCore `const` at top-level doesn't create accessible global properties)
/// - `export function` → `function`
/// - `export default` → `var __default =`
public nonisolated enum CanvasSourcePreprocessor {
    /// Transforms template source for JSCore evaluation.
    ///
    /// Only matches `export` at the start of a line (with optional leading whitespace).
    /// Does not transform `export` that appears mid-line (e.g. inside strings or comments).
    ///
    /// - Parameter source: The raw template JavaScript source
    /// - Returns: Preprocessed source suitable for `JSContext.evaluateScript`
    public static func preprocess(_ source: String) -> String {
        source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { preprocessLine(String($0)) }
            .joined(separator: "\n")
    }

    private nonisolated(unsafe) static let exportConst = try! Regex(#"^(\s*)export\s+const\s+"#)
    private nonisolated(unsafe) static let exportLet = try! Regex(#"^(\s*)export\s+let\s+"#)
    private nonisolated(unsafe) static let exportFunction = try! Regex(#"^(\s*)export\s+function\s+"#)
    private nonisolated(unsafe) static let exportDefault = try! Regex(#"^(\s*)export\s+default\s+"#)

    private static func preprocessLine(_ line: String) -> String {
        if let match = try? exportConst.firstMatch(in: line) {
            let leading = match.output[1].substring.map(String.init) ?? ""
            var result = line
            result.replaceSubrange(match.range, with: "\(leading)var ")
            return result
        }
        if let match = try? exportLet.firstMatch(in: line) {
            let leading = match.output[1].substring.map(String.init) ?? ""
            var result = line
            result.replaceSubrange(match.range, with: "\(leading)var ")
            return result
        }
        if let match = try? exportFunction.firstMatch(in: line) {
            let leading = match.output[1].substring.map(String.init) ?? ""
            var result = line
            result.replaceSubrange(match.range, with: "\(leading)function ")
            return result
        }
        if let match = try? exportDefault.firstMatch(in: line) {
            let leading = match.output[1].substring.map(String.init) ?? ""
            var result = line
            result.replaceSubrange(match.range, with: "\(leading)var __default = ")
            return result
        }
        return line
    }
}
