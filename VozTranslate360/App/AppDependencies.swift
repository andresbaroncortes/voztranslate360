//
//  AppDependencies.swift
//  VozTranslate 360 — Atlas Business
//
//  Contenedor de dependencias. Es el único lugar donde se decide qué
//  implementación (simulada o real) usa cada servicio.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppDependencies {
    let translator: any TranslationProviding
    let recognizer: any SpeechRecognitionProviding
    let synthesizer: any SpeechSynthesizing
    let connectivity: any ConnectivityMonitoring

    init(
        translator: any TranslationProviding,
        recognizer: any SpeechRecognitionProviding,
        synthesizer: any SpeechSynthesizing,
        connectivity: any ConnectivityMonitoring
    ) {
        self.translator = translator
        self.recognizer = recognizer
        self.synthesizer = synthesizer
        self.connectivity = connectivity
    }

    /// Fase 1: todos los servicios son simulados.
    static func mock() -> AppDependencies {
        AppDependencies(
            translator: MockTranslationService(),
            recognizer: MockSpeechRecognizer(),
            synthesizer: MockSpeechSynthesizer(),
            connectivity: MockConnectivityMonitor()
        )
    }

    /// Dependencias que usa la app. Cada fase cambiará aquí un servicio
    /// simulado por el real.
    static func makeDefault() -> AppDependencies {
        mock()
    }
}
