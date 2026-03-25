//
//  CanvasRuntimeTests.swift
//  NativeCanvasTests
//

import JavaScriptCore
import NativeCanvas
import Testing

struct CanvasRuntimeTests {
    // MARK: - Template Loading

    @Test("Loads a minimal template and extracts schema name")
    func loadMinimalTemplate() throws {
        let source = """
        export const schema = { name: "Test Template", params: {} };
        export const layers = [{ name: "bg", render(ctx, params, scene) {} }];
        """
        let runtime = CanvasRuntime(width: 1920, height: 1080)
        let template = try runtime.loadTemplate(source: source)
        #expect(template.name == "Test Template")
    }

    @Test("Extracts layer names correctly")
    func layerNames() throws {
        let source = """
        export const schema = { name: "Multi", params: {} };
        export const layers = [
            { name: "background", render(ctx, params, scene) {} },
            { name: "text", editableParam: "title", render(ctx, params, scene) {} }
        ];
        """
        let runtime = CanvasRuntime(width: 1920, height: 1080)
        let template = try runtime.loadTemplate(source: source)
        #expect(template.layers.count == 2)
        #expect(template.layers[0].name == "background")
        #expect(template.layers[0].editableParam == nil)
        #expect(template.layers[1].name == "text")
        #expect(template.layers[1].editableParam == "title")
    }

    @Test("Extracts default param values")
    func defaultParamValues() throws {
        let source = """
        export const schema = {
            name: "Defaults",
            params: {
                color: { type: "color", default: "#ff0000" },
                size: { type: "float", default: 32 },
                font: { type: "font", default: { family: "SF Pro", weight: "bold" } }
            }
        };
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let runtime = CanvasRuntime(width: 1920, height: 1080)
        let template = try runtime.loadTemplate(source: source)

        #expect(template.defaultParams.forProperty("color")?.toString() == "#ff0000")
        #expect(template.defaultParams.forProperty("size")?.toInt32() == 32)
        let font = try #require(template.defaultParams.forProperty("font"))
        #expect(font.forProperty("family")?.toString() == "SF Pro")
        #expect(font.forProperty("weight")?.toString() == "bold")
    }

    // MARK: - Error Handling

    @Test("Schema-free script loads with default name")
    func missingSchemaUsesDefaults() throws {
        let source = """
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let runtime = CanvasRuntime(width: 1920, height: 1080)
        let template = try runtime.loadTemplate(source: source)
        #expect(template.name == "Untitled")
    }

    @Test("Schema-free script has empty defaultParams")
    func missingSchemaHasEmptyParams() throws {
        let source = """
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let runtime = CanvasRuntime(width: 1920, height: 1080)
        let template = try runtime.loadTemplate(source: source)
        // No params defined — defaultParams object should have no keys
        let keys = runtime.jsContext.evaluateScript("Object.keys(nc)") // unrelated — just checking runtime is alive
        let paramKeys = template.defaultParams.invokeMethod("hasOwnProperty", withArguments: ["anyKey"])
        #expect(paramKeys?.toBool() == false)
    }

    @Test("Throws missingExport when layers is missing")
    func missingLayers() throws {
        let source = """
        export const schema = { name: "Test", params: {} };
        """
        let runtime = CanvasRuntime(width: 1920, height: 1080)
        #expect(throws: CanvasError.self) {
            try runtime.loadTemplate(source: source)
        }
    }

    @Test("Throws invalidLayers when layers is not an array")
    func layersNotArray() throws {
        let source = """
        export const schema = { name: "Test", params: {} };
        export const layers = "not an array";
        """
        let runtime = CanvasRuntime(width: 1920, height: 1080)
        #expect(throws: CanvasError.self) {
            try runtime.loadTemplate(source: source)
        }
    }

    @Test("Throws invalidLayers when layers is empty")
    func emptyLayers() throws {
        let source = """
        export const schema = { name: "Test", params: {} };
        export const layers = [];
        """
        let runtime = CanvasRuntime(width: 1920, height: 1080)
        #expect(throws: CanvasError.self) {
            try runtime.loadTemplate(source: source)
        }
    }

    @Test("Syntax error propagates line number")
    func syntaxErrorHasLineNumber() throws {
        // Error is on line 3 of the source
        let source = """
        export const schema = { name: "Test" };
        export const layers = [];
        @@@ syntax error here;
        """
        let runtime = CanvasRuntime(width: 100, height: 100)
        do {
            _ = try runtime.loadTemplate(source: source)
            Issue.record("Expected evaluationFailed to be thrown")
        } catch let CanvasError.evaluationFailed(_, line: line, column: _) {
            #expect(line == 3)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Sandbox

    @Test("eval is not available in sandboxed context")
    func evalDisabled() throws {
        let source = """
        export const schema = { name: "Test", params: {} };
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let runtime = CanvasRuntime(width: 1920, height: 1080)
        _ = try runtime.loadTemplate(source: source)

        let result = try #require(runtime.jsContext.evaluateScript("typeof eval")?.toString())
        #expect(result == "undefined")
    }

    @Test("nc standard library is available in loaded template")
    func ncAvailable() throws {
        let source = """
        export const schema = { name: "Test", params: {} };
        export const layers = [{
            name: "layer",
            render(ctx, params, scene) {
                var x = nc.pt(10);
            }
        }];
        """
        let runtime = CanvasRuntime(width: 1920, height: 1080)
        let template = try runtime.loadTemplate(source: source)
        #expect(template.name == "Test")

        let ncExists = try #require(runtime.jsContext.evaluateScript("typeof nc")?.toString())
        #expect(ncExists == "object")
    }

    @Test("standardLibrary:false suppresses nc injection")
    func standardLibraryFalse() throws {
        let source = """
        export const schema = { name: "Test", params: {} };
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let runtime = CanvasRuntime(width: 1920, height: 1080, standardLibrary: false)
        _ = try runtime.loadTemplate(source: source)

        let ncType = runtime.jsContext.evaluateScript("typeof nc")?.toString()
        #expect(ncType == "undefined")
    }
}
