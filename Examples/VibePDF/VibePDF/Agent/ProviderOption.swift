//
//  ProviderOption.swift
//  VibePDF
//

import Foundation
import NativeCanvas
import Operator

enum ProviderOption: String, CaseIterable, Friendly {
    case anthropic
    case openAI
    case openRouter
    case mistral
    case lmStudio
    case appleIntelligence

    var displayName: String {
        switch self {
        case .anthropic: "Anthropic"
        case .openAI: "OpenAI"
        case .openRouter: "OpenRouter"
        case .mistral: "Mistral"
        case .lmStudio: "LM Studio"
        case .appleIntelligence: "Apple Intelligence"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .lmStudio, .appleIntelligence: false
        default: true
        }
    }

    var requiresModelName: Bool {
        switch self {
        case .openRouter, .lmStudio: true
        default: false
        }
    }

    /// Whether this provider uses the quality tier picker instead of a free-form model name.
    var supportsTierSelection: Bool {
        switch self {
        case .openRouter, .lmStudio, .appleIntelligence: false
        default: true
        }
    }

    /// Whether this provider supports vision for a given model name.
    func supportsVision(modelName: String) -> Bool {
        switch self {
        case .anthropic, .openAI: true
        case .mistral, .appleIntelligence: false
        case .openRouter, .lmStudio:
            Operator.ModelName(rawValue: modelName).supportsVision ?? false
        }
    }

    func resolveProvider(apiKey: String) -> Operator.Provider {
        switch self {
        case .anthropic:
            Operator.Provider.anthropic(apiKey: apiKey)
        case .openAI:
            Operator.Provider.openAI(apiKey: apiKey)
        case .openRouter:
            // swiftlint:disable:next force_unwrapping
            Operator.Provider.other(URL(string: "https://openrouter.ai/api")!, apiKey: apiKey)
        case .mistral:
            Operator.Provider.mistral(apiKey: apiKey)
        case .lmStudio, .appleIntelligence:
            Operator.Provider.lmStudio
        }
    }
}
