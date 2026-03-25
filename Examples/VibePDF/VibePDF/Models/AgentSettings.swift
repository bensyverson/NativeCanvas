//
//  AgentSettings.swift
//  VibePDF
//

import Foundation
import KeyManager
import NativeCanvas
import Observation
import Operator

@Observable final class AgentSettings {
    var provider: ProviderOption = .anthropic {
        didSet {
            UserDefaults.standard.set(provider.rawValue, forKey: Keys.provider)
            guard !_isKeychainLoading else { return }
            loadAPIKey()
        }
    }

    var apiKey: String = "" {
        didSet {
            guard !_isKeychainLoading else { return }
            saveAPIKey()
        }
    }

    var modelType: Operator.ModelType = .standard {
        didSet { UserDefaults.standard.set(modelType.rawValue, forKey: Keys.modelType) }
    }

    var modelName: String = "" {
        didSet { UserDefaults.standard.set(modelName, forKey: Keys.modelName) }
    }

    var docWidth: Double = 8.5 {
        didSet { UserDefaults.standard.set(docWidth, forKey: Keys.docWidth) }
    }

    var docHeight: Double = 11.0 {
        didSet { UserDefaults.standard.set(docHeight, forKey: Keys.docHeight) }
    }

    var docUnit: DocUnit = .inches {
        didSet { UserDefaults.standard.set(docUnit.rawValue, forKey: Keys.docUnit) }
    }

    var hasAPIKey: Bool {
        !provider.requiresAPIKey || !apiKey.isEmpty
    }

    var pixelWidth: Int {
        docUnit.toPixels(docWidth)
    }

    var pixelHeight: Int {
        docUnit.toPixels(docHeight)
    }

    var viewport: CanvasViewport {
        CanvasViewport(width: pixelWidth, height: pixelHeight)
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let provider = "agentSettings.provider"
        static let modelType = "agentSettings.modelType"
        static let modelName = "agentSettings.modelName"
        static let docWidth = "agentSettings.docWidth"
        static let docHeight = "agentSettings.docHeight"
        static let docUnit = "agentSettings.docUnit"
    }

    // MARK: - Keychain

    private let keyManager = KeyManager(service: "com.bensyverson.VibePDF")
    private var _isKeychainLoading = false

    init() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: Keys.provider),
           let saved = ProviderOption(rawValue: raw)
        { provider = saved }
        if let raw = defaults.string(forKey: Keys.modelType),
           let saved = Operator.ModelType(rawValue: raw)
        { modelType = saved }
        if let saved = defaults.string(forKey: Keys.modelName) { modelName = saved }
        let savedWidth = defaults.double(forKey: Keys.docWidth)
        if savedWidth > 0 { docWidth = savedWidth }
        let savedHeight = defaults.double(forKey: Keys.docHeight)
        if savedHeight > 0 { docHeight = savedHeight }
        if let raw = defaults.string(forKey: Keys.docUnit),
           let saved = DocUnit(rawValue: raw)
        { docUnit = saved }
        loadAPIKey()
    }

    private func loadAPIKey() {
        _isKeychainLoading = true
        apiKey = (try? keyManager.value(for: provider.rawValue)) ?? ""
        _isKeychainLoading = false
    }

    private func saveAPIKey() {
        if apiKey.isEmpty {
            try? keyManager.remove(key: provider.rawValue)
        } else {
            try? keyManager.store(key: provider.rawValue, value: apiKey)
        }
    }
}
