//
//  VozTranslate360App.swift
//  VozTranslate 360 — Atlas Business
//
//  Punto de entrada. Crea las dependencias, los ajustes, el ViewModel de
//  la conversación y el contenedor de SwiftData, y los inyecta en el
//  entorno de SwiftUI.
//

import SwiftUI
import SwiftData

@main
struct VozTranslate360App: App {
    @State private var dependencies: AppDependencies
    @State private var settings: AppSettings
    @State private var conversation: ConversationViewModel

    init() {
        let dependencies = AppDependencies.makeDefault()
        let settings = AppSettings()
        _dependencies = State(initialValue: dependencies)
        _settings = State(initialValue: settings)
        let conversation = ConversationViewModel(dependencies: dependencies, settings: settings)
        #if DEBUG
        if DemoMode.isEnabled { conversation.loadDemoConversation() }
        #endif
        _conversation = State(initialValue: conversation)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(dependencies)
                .environment(settings)
                .environment(conversation)
        }
        .modelContainer(for: ConversationEntry.self)
    }
}
