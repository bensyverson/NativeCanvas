//
//  CanvasSchemaTests.swift
//  NativeCanvasTests
//

import Foundation
import NativeCanvas
import Testing

struct CanvasSchemaTests {
    // MARK: - Helpers

    private func makeSchema(source: String) throws -> CanvasSchema {
        let runtime = CanvasRuntime(width: 1920, height: 1080)
        _ = try runtime.loadTemplate(source: source)
        guard let schema = runtime.extractSchema() else {
            throw CanvasError.missingExport("schema")
        }
        return schema
    }

    // MARK: - Tests

    @Test("Extracts name, description, and version from JS source")
    func basicMetadata() throws {
        let source = """
        export const schema = {
            name: "Lower Third",
            description: "A simple lower third graphic",
            version: "2.1.0",
            category: "Lower Thirds",
            params: {}
        };
        export const layers = [{ name: "bg", render(ctx, params, scene) {} }];
        """
        let schema = try makeSchema(source: source)
        #expect(schema.name == "Lower Third")
        #expect(schema.description == "A simple lower third graphic")
        #expect(schema.version == "2.1.0")
        #expect(schema.category == "Lower Thirds")
    }

    @Test("Extracts params with correct types and defaults")
    func paramsExtraction() throws {
        let source = """
        export const schema = {
            name: "Test",
            params: {
                title: { type: "string", default: "Hello World" },
                size: { type: "float", default: 32, min: 8, max: 120, animatable: true },
                visible: { type: "bool", default: true },
                color: { type: "color", default: "#ff0000" }
            }
        };
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let schema = try makeSchema(source: source)
        #expect(schema.params.count == 4)

        let title = try #require(schema.param(named: "title"))
        #expect(title.type == .string)
        #expect(title.defaultValue == .string("Hello World"))

        let size = try #require(schema.param(named: "size"))
        #expect(size.type == .float)
        #expect(size.defaultValue == .number(32))
        #expect(size.min == 8)
        #expect(size.max == 120)
        #expect(size.animatable == true)

        let visible = try #require(schema.param(named: "visible"))
        #expect(visible.type == .bool)
        #expect(visible.defaultValue == .bool(true))
    }

    @Test("Missing optional fields default gracefully")
    func missingOptionalFields() throws {
        let source = """
        export const schema = { name: "Minimal", params: {} };
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let schema = try makeSchema(source: source)
        #expect(schema.author == nil)
        #expect(schema.paramGroups == nil)
        #expect(schema.tags.isEmpty)
        #expect(schema.description == "")
        #expect(schema.version == "1.0.0")
        #expect(schema.category == "Uncategorized")
    }

    @Test("param(named:) lookup works for existing and missing keys")
    func paramNamedLookup() throws {
        let source = """
        export const schema = {
            name: "Test",
            params: {
                title: { type: "string", default: "Hello" }
            }
        };
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let schema = try makeSchema(source: source)
        #expect(schema.param(named: "title") != nil)
        #expect(schema.param(named: "nonexistent") == nil)
    }

    @Test("Extracts defaultDuration as Double seconds when present in schema")
    func defaultDurationPresent() throws {
        let source = """
        export const schema = {
            name: "Timed",
            defaultDuration: 3.5,
            params: {}
        };
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let schema = try makeSchema(source: source)
        #expect(schema.defaultDuration == 3.5)
    }

    @Test("defaultDuration is nil when omitted from schema")
    func defaultDurationMissing() throws {
        let source = """
        export const schema = {
            name: "No Duration",
            params: {}
        };
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let schema = try makeSchema(source: source)
        #expect(schema.defaultDuration == nil)
    }

    @Test("defaultDuration is nil for non-numeric values")
    func defaultDurationMalformed() throws {
        let source = """
        export const schema = {
            name: "Bad Duration",
            defaultDuration: "not a number",
            params: {}
        };
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let schema = try makeSchema(source: source)
        #expect(schema.defaultDuration == nil)
    }

    @Test("defaultDuration Codable round-trip preserves value")
    func defaultDurationCodableRoundTrip() throws {
        let source = """
        export const schema = {
            name: "Timed",
            defaultDuration: 7.25,
            params: {}
        };
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let schema = try makeSchema(source: source)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(schema)
        let decoded = try decoder.decode(CanvasSchema.self, from: data)
        #expect(decoded.defaultDuration == schema.defaultDuration)
    }

    @Test("Schema Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let source = """
        export const schema = {
            name: "Full Schema",
            description: "A test template",
            version: "1.2.3",
            category: "Test",
            tags: ["test", "demo"],
            author: { name: "Test Author", url: "https://example.com" },
            params: {
                title: { type: "string", default: "Hello" },
                size: { type: "float", default: 24, min: 8, max: 72 }
            },
            paramGroups: {
                "Text": ["title", "size"]
            }
        };
        export const layers = [{ name: "layer", render(ctx, params, scene) {} }];
        """
        let schema = try makeSchema(source: source)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(schema)
        let decoded = try decoder.decode(CanvasSchema.self, from: data)

        #expect(decoded.name == schema.name)
        #expect(decoded.description == schema.description)
        #expect(decoded.version == schema.version)
        #expect(decoded.category == schema.category)
        #expect(decoded.tags == schema.tags)
        #expect(decoded.author == schema.author)
        #expect(decoded.params.count == schema.params.count)
        #expect(decoded.paramGroups == schema.paramGroups)
    }
}
