//
//  SettingsSidebarView.swift
//  VibePDF
//

import Operator
import SwiftUI

struct SettingsSidebarView: View {
    @Environment(DocumentCoordinator.self) private var coordinator

    var body: some View {
        let settings = coordinator.settings
        Form {
            Section("Document Size") {
                TextField("Width", value: Bindable(settings).docWidth, format: .number)

                TextField("Height", value: Bindable(settings).docHeight, format: .number)

                Picker("Units", selection: Bindable(settings).docUnit) {
                    ForEach(DocUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
            }

            Section("AI Provider") {
                Picker("Provider", selection: Bindable(settings).provider) {
                    ForEach(ProviderOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }

                if settings.provider.requiresAPIKey {
                    SecureField("API Key", text: Bindable(settings).apiKey)
                        .autocorrectionDisabled()
                }

                if settings.provider.supportsTierSelection {
                    Picker("Quality", selection: Bindable(settings).modelType) {
                        Text("High").tag(Operator.ModelType.flagship)
                        Text("Medium").tag(Operator.ModelType.standard)
                        Text("Low").tag(Operator.ModelType.fast)
                    }
                    .pickerStyle(.segmented)
                }

                if settings.provider.requiresModelName {
                    TextField("Model Name", text: Bindable(settings).modelName)
                        .autocorrectionDisabled()
                }
            }
        }
        .navigationTitle("Settings")
        .onChange(of: settings.provider) { coordinator.buildOperative() }
        .onChange(of: settings.apiKey) { coordinator.buildOperative() }
        .onChange(of: settings.modelName) { coordinator.buildOperative() }
        .onChange(of: settings.modelType) { coordinator.buildOperative() }
    }
}

#Preview {
    SettingsSidebarView()
        .environment(DocumentCoordinator())
}
