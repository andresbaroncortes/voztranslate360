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
    let availability: any LanguageAvailabilityChecking
    let recognizer: any SpeechRecognitionProviding
    let synthesizer: any SpeechSynthesizing
    let connectivity: any ConnectivityMonitoring

    init(
        translator: any TranslationProviding,
        availability: any LanguageAvailabilityChecking,
        recognizer: any SpeechRecognitionProviding,
        synthesizer: any SpeechSynthesizing,
        connectivity: any ConnectivityMonitoring
    ) {
        self.translator = translator
        self.availability = availability
        self.recognizer = recognizer
        self.synthesizer = synthesizer
        self.connectivity = connectivity
    }

    /// Todo simulado: pruebas automáticas, Previews y capturas.
    /// - Parameter overrides: estado forzado de ciertos idiomas.
    static func mock(availability overrides: [AppLanguage: PairAvailability] = [:]) -> AppDependencies {
        let checker = MockLanguageAvailability(overrides: overrides)
        return AppDependencies(
            translator: MockTranslationService(availability: checker),
            availability: checker,
            recognizer: MockSpeechRecognizer(),
            synthesizer: MockSpeechSynthesizer(),
            connectivity: MockConnectivityMonitor()
        )
    }

    /// Servicios reales disponibles hasta la fase actual.
    /// Fase 2: traducción y disponibilidad reales; dictado, voz y
    /// conectividad siguen simulados (Fases 3 y 5).
    static func live() -> AppDependencies {
        let checker = AppleLanguageAvailabilityService()
        return AppDependencies(
            translator: AppleTranslationService(availability: checker),
            availability: checker,
            recognizer: MockSpeechRecognizer(),
            synthesizer: MockSpeechSynthesizer(),
            connectivity: MockConnectivityMonitor()
        )
    }

    static func makeDefault() -> AppDependencies {
        if DemoMode.usesMockServices {
            // En las capturas se muestran estados variados (simulados).
            return mock(availability: [.german: .needsDownload, .portuguese: .needsDownload])
        }
        return live()
    }
}
