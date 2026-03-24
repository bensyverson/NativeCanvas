//
//  CanvasSchema.swift
//  NativeCanvas
//

import Foundation
import JavaScriptCore

/// The full parsed schema from a template's `schema` export.
///
/// Params use an ordered array of ``ParamEntry`` to preserve the template
/// author's intended parameter ordering for the UI.
public struct CanvasSchema: Friendly {
    /// Template display name.
    public let name: String
    /// Template description.
    public let description: String
    /// Semantic version string.
    public let version: String
    /// Category for grouping (e.g. "Lower Thirds", "Transitions").
    public let category: String
    /// Searchable tags.
    public let tags: [String]
    /// Optional author information.
    public let author: Author?
    /// Ordered parameter definitions.
    public let params: [ParamEntry]
    /// Optional parameter grouping for UI sections.
    public let paramGroups: [String: [String]]?
    /// Default duration in seconds. `nil` = use app default.
    public let defaultDuration: Double?

    /// Author metadata for a template.
    public struct Author: Friendly {
        public let name: String
        public let url: String?

        public init(name: String, url: String?) {
            self.name = name
            self.url = url
        }
    }

    /// A named parameter definition, preserving insertion order.
    public struct ParamEntry: Friendly {
        public let key: String
        public let definition: CanvasParamDef

        public init(key: String, definition: CanvasParamDef) {
            self.key = key
            self.definition = definition
        }
    }

    public init(
        name: String,
        description: String,
        version: String,
        category: String,
        tags: [String],
        author: Author?,
        params: [ParamEntry],
        paramGroups: [String: [String]]?,
        defaultDuration: Double?
    ) {
        self.name = name
        self.description = description
        self.version = version
        self.category = category
        self.tags = tags
        self.author = author
        self.params = params
        self.paramGroups = paramGroups
        self.defaultDuration = defaultDuration
    }

    /// Looks up a parameter definition by key.
    public func param(named key: String) -> CanvasParamDef? {
        params.first(where: { $0.key == key })?.definition
    }
}

// MARK: - JSValue Extraction

extension CanvasSchema {
    /// Extracts a `CanvasSchema` from a JSValue representing the template's schema object.
    public nonisolated static func from(_ schemaValue: JSValue) -> CanvasSchema? {
        guard !schemaValue.isUndefined, !schemaValue.isNull else { return nil }

        let name = schemaValue.forProperty("name").flatMap { $0.isUndefined ? nil : $0.toString() } ?? "Untitled"
        let description = schemaValue.forProperty("description").flatMap { $0.isUndefined ? nil : $0.toString() } ?? ""
        let version = schemaValue.forProperty("version").flatMap { $0.isUndefined ? nil : $0.toString() } ?? "1.0.0"
        let category = schemaValue.forProperty("category").flatMap { $0.isUndefined ? nil : $0.toString() } ?? "Uncategorized"

        // Tags
        let tags: [String] = {
            guard let tagsVal = schemaValue.forProperty("tags"),
                  !tagsVal.isUndefined, tagsVal.isArray
            else { return [] }
            let count = tagsVal.forProperty("length")?.toInt32() ?? 0
            return (0 ..< Int(count)).map { tagsVal.atIndex($0)!.toString() }
        }()

        // Author
        let author: Author? = {
            guard let authorVal = schemaValue.forProperty("author"),
                  !authorVal.isUndefined, !authorVal.isNull,
                  authorVal.isObject
            else { return nil }
            let authorName = authorVal.forProperty("name")?.toString() ?? "Unknown"
            let url: String? = {
                guard let u = authorVal.forProperty("url"),
                      !u.isUndefined, !u.isNull
                else { return nil }
                return u.toString()
            }()
            return Author(name: authorName, url: url)
        }()

        // Params (ordered)
        var paramEntries: [ParamEntry] = []
        if let paramsVal = schemaValue.forProperty("params"),
           !paramsVal.isUndefined, !paramsVal.isNull
        {
            guard let context = schemaValue.context else { return nil }
            if let keys = context.evaluateScript("(function(obj) { return Object.keys(obj); })")?.call(withArguments: [paramsVal]),
               keys.isArray
            {
                let keyCount = keys.forProperty("length")?.toInt32() ?? 0
                for i in 0 ..< Int(keyCount) {
                    let key = keys.atIndex(i)!.toString()!
                    let paramVal = paramsVal.forProperty(key)!
                    let def = CanvasParamDef.from(paramVal)
                    paramEntries.append(ParamEntry(key: key, definition: def))
                }
            }
        }

        // Param groups
        let paramGroups: [String: [String]]? = {
            guard let groupsVal = schemaValue.forProperty("paramGroups"),
                  !groupsVal.isUndefined, !groupsVal.isNull,
                  groupsVal.isObject
            else { return nil }
            guard let context = schemaValue.context else { return nil }
            var groups: [String: [String]] = [:]
            if let keys = context.evaluateScript("(function(obj) { return Object.keys(obj); })")?.call(withArguments: [groupsVal]),
               keys.isArray
            {
                let keyCount = keys.forProperty("length")?.toInt32() ?? 0
                for i in 0 ..< Int(keyCount) {
                    let key = keys.atIndex(i)!.toString()!
                    let arrVal = groupsVal.forProperty(key)!
                    if arrVal.isArray {
                        let count = arrVal.forProperty("length")?.toInt32() ?? 0
                        groups[key] = (0 ..< Int(count)).map { arrVal.atIndex($0)!.toString() }
                    }
                }
            }
            return groups.isEmpty ? nil : groups
        }()

        // Default duration (seconds)
        let defaultDuration: Double? = {
            guard let durVal = schemaValue.forProperty("defaultDuration"),
                  !durVal.isUndefined, !durVal.isNull,
                  durVal.isNumber
            else { return nil }
            let seconds = durVal.toDouble()
            guard seconds.isFinite, seconds > 0 else { return nil }
            return seconds
        }()

        return CanvasSchema(
            name: name,
            description: description,
            version: version,
            category: category,
            tags: tags,
            author: author,
            params: paramEntries,
            paramGroups: paramGroups,
            defaultDuration: defaultDuration
        )
    }
}
