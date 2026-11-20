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
    static func mock(availability overrides: [AppLanguage: PairAvailability] = [:],
                     isConnected: Bool = true) -> AppDependencies {
        let checker = MockLanguageAvailability(overrides: overrides)
        let connectivity = MockConnectivityMonitor(isConnected: isConnected)
        return AppDependencies(
            translator: MockTranslationService(availability: checker, connectivity: connectivity),
            availability: checker,
            recognizer: MockSpeechRecognizer(),
            synthesizer: MockSpeechSynthesizer(),
            connectivity: connectivity
        )
    }

    /// Todos los servicios reales (desde la Fase 5 ya no queda nada simulado).
    static func live() -> AppDependencies {
        let checker = AppleLanguageAvailabilityService()
        let connectivity = NetworkConnectivityMonitor()
        return AppDependencies(
            translator: AppleTranslationService(availability: checker, connectivity: connectivity),
            availability: checker,
            recognizer: AppleSpeechRecognizer(connectivity: connectivity),
            synthesizer: AppleSpeechSynthesizer(),
            connectivity: connectivity
        )
    }

    static func makeDefault() -> AppDependencies {
        if DemoMode.usesMockServices {
            // En las capturas se muestran estados variados (simulados).
            return mock(availability: [.german: .needsDownload, .portuguese: .needsDownload],
                        isConnected: !DemoMode.simulatesOffline)
        }
        return live()
    }
}
