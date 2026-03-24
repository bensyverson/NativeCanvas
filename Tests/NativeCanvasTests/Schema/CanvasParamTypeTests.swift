//
//  CanvasParamTypeTests.swift
//  NativeCanvasTests
//

import Foundation
import NativeCanvas
import Testing

struct CanvasParamTypeTests {
    @Test("Each known type string maps to the correct case")
    func knownTypes() {
        #expect(CanvasParamType(rawString: "string") == .string)
        #expect(CanvasParamType(rawString: "text") == .text)
        #expect(CanvasParamType(rawString: "float") == .float)
        #expect(CanvasParamType(rawString: "int") == .int)
        #expect(CanvasParamType(rawString: "bool") == .bool)
        #expect(CanvasParamType(rawString: "color") == .color)
        #expect(CanvasParamType(rawString: "enum") == .enumType)
        #expect(CanvasParamType(rawString: "font") == .font)
        #expect(CanvasParamType(rawString: "point2d") == .point2d)
        #expect(CanvasParamType(rawString: "gradient") == .gradient)
        #expect(CanvasParamType(rawString: "image") == .image)
    }

    @Test("Unknown type string produces .unknown case")
    func unknownType() {
        let paramType = CanvasParamType(rawString: "newtype")
        #expect(paramType == .unknown("newtype"))
        #expect(paramType.rawString == "newtype")
    }

    @Test("Codable round-trip preserves all known types")
    func codableRoundTripKnown() throws {
        let allKnown: [CanvasParamType] = [
            .string, .text, .float, .int, .bool,
            .color, .enumType, .font, .point2d, .gradient, .image,
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for paramType in allKnown {
            let data = try encoder.encode(paramType)
            let decoded = try decoder.decode(CanvasParamType.self, from: data)
            #expect(decoded == paramType, "Round-trip failed for \(paramType.rawString)")
        }
    }

    @Test("Codable round-trip preserves unknown types")
    func codableRoundTripUnknown() throws {
        let paramType = CanvasParamType.unknown("futuristic")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(paramType)
        let decoded = try decoder.decode(CanvasParamType.self, from: data)
        #expect(decoded == .unknown("futuristic"))
    }

    @Test("rawString is symmetric with init(rawString:)")
    func rawStringSymmetry() {
        let allKnown: [CanvasParamType] = [
            .string, .text, .float, .int, .bool,
            .color, .enumType, .font, .point2d, .gradient, .image,
        ]
        for paramType in allKnown {
            #expect(CanvasParamType(rawString: paramType.rawString) == paramType)
        }
    }
}
