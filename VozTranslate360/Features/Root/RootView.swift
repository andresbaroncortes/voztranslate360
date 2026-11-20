//
//  RootView.swift
//  VozTranslate 360 — Atlas Business
//
//  Navegación principal por pestañas.
//

import SwiftUI
import SwiftData

/// Pestañas de la app. El valor de texto se usa en el modo demostración.
nonisolated enum AppTab: String, Hashable {
    case translate = "traducir"
    case history = "historial"
    case settings = "ajustes"
}

struct RootView: View {
    @State private var selection: AppTab = DemoMode.initialTab

    var body: some View {
        TabView(selection: $selection) {
            Tab("Traducir", systemImage: "waveform.and.mic", value: AppTab.translate) {
                ConversationView()
            }
            Tab("Historial", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView()
            }
            Tab("Ajustes", systemImage: "gearshape", value: AppTab.settings) {
                SettingsView()
            }
        }
        // Conexión con Apple Translation: siempre presente en la jerarquía.
        .background { TranslationSessionHost() }
    }
}

#Preview {
    let dependencies = AppDependencies.mock()
    let settings = AppSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    return RootView()
        .environment(dependencies)
        .environment(settings)
        .environment(ConversationViewModel(dependencies: dependencies, settings: settings))
        .modelContainer(for: ConversationEntry.self, inMemory: true)
}
