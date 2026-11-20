//
//  Fase2TranslationTests.swift
//  VozTranslate 360 — Atlas Business
//
//  Pruebas de la Fase 2: texto escrito, reglas de modo sin conexión,
//  errores visibles y disponibilidad REAL consultada a Apple Translation.
//

import Foundation
import Testing
import Translation
@testable import VozTranslate360

/// Traductor que siempre falla, para comprobar cómo se informa el error.
@MainActor
private final class FailingTranslator: TranslationProviding {
    let error: TranslationServiceError
    init(error: TranslationServiceError) { self.error = error }
    func translate(_ text: String, from source: AppLanguage, to target: AppLanguage,
                   mode: ProcessingMode) async throws -> TranslationResult {
        throw error
    }
}

@MainActor
struct Fase2TranslationTests {

    private func makeSettings(mode: ProcessingMode = .automatic) -> AppSettings {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "tests.\(UUID().uuidString)")!)
        settings.autoSpeak = false
        settings.processingMode = mode
        return settings
    }

    private func waitUntil(timeout: Duration = .seconds(10), _ condition: () -> Bool) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return condition()
    }

    // MARK: Texto escrito

    @Test func textoEscritoSeTraduce() async throws {
        let viewModel = ConversationViewModel(dependencies: .mock(), settings: makeSettings())
        viewModel.translateTyped("  \(AppLanguage.spanish.samplePhrase)  ")
        #expect(viewModel.phase == .translating(.me))

        let finished = await waitUntil { viewModel.turns.count == 1 && viewModel.phase == .idle }
        #expect(finished)
        let turn = try #require(viewModel.turns.first)
        #expect(turn.originalText == AppLanguage.spanish.samplePhrase)
        #expect(turn.translatedText == AppLanguage.english.samplePhrase)
    }

    @Test func textoVacioSeIgnora() {
        let viewModel = ConversationViewModel(dependencies: .mock(), settings: makeSettings())
        viewModel.translateTyped("   ")
        #expect(viewModel.phase == .idle)
        #expect(viewModel.turns.isEmpty)
    }

    // MARK: Reglas de disponibilidad

    @Test func politicaPermiteInstalado() throws {
        for mode in ProcessingMode.allCases {
            try TranslationPolicy.validate(.installed, from: .spanish, to: .english, mode: mode)
        }
    }

    @Test func politicaPermiteDescargaConConexion() throws {
        try TranslationPolicy.validate(.needsDownload, from: .spanish, to: .german, mode: .automatic)
        try TranslationPolicy.validate(.needsDownload, from: .spanish, to: .german, mode: .online)
    }

    @Test func politicaSinConexionAvisaSiFaltaDescarga() {
        #expect(throws: TranslationServiceError.offlineResourceMissing(.spanish, .german)) {
            try TranslationPolicy.validate(.needsDownload, from: .spanish, to: .german, mode: .offline)
        }
    }

    @Test func politicaRechazaParNoAdmitido() {
        for mode in ProcessingMode.allCases {
            #expect(throws: TranslationServiceError.unsupportedPair(.spanish, .italian)) {
                try TranslationPolicy.validate(.unsupported, from: .spanish, to: .italian, mode: mode)
            }
        }
    }

    @Test func modoSinConexionMuestraAvisoClaro() async {
        let dependencies = AppDependencies.mock(availability: [.english: .needsDownload])
        let viewModel = ConversationViewModel(dependencies: dependencies, settings: makeSettings(mode: .offline))
        viewModel.translateTyped("Hola")

        let finished = await waitUntil { viewModel.phase == .idle }
        #expect(finished)
        #expect(viewModel.turns.isEmpty)
        #expect(viewModel.errorMessage == TranslationServiceError.offlineResourceMissing(.spanish, .english).errorDescription)
    }

    @Test func errorDeTraduccionSeInformaYVuelveAReposo() async {
        let mock = AppDependencies.mock()
        let dependencies = AppDependencies(
            translator: FailingTranslator(error: .translationFailed("Prueba")),
            availability: mock.availability,
            recognizer: mock.recognizer,
            synthesizer: mock.synthesizer,
            connectivity: mock.connectivity
        )
        let viewModel = ConversationViewModel(dependencies: dependencies, settings: makeSettings())
        viewModel.toggleListening(for: .partner)

        let finished = await waitUntil { viewModel.errorMessage != nil && viewModel.phase == .idle }
        #expect(finished)
        #expect(viewModel.turns.isEmpty)
        #expect(viewModel.liveTranscript.isEmpty)
    }

    @Test func mismoIdiomaNoLlamaAlModelo() async throws {
        let service = AppleTranslationService(availability: MockLanguageAvailability())
        let result = try await service.translate("Hola", from: .spanish, to: .spanish, mode: .offline)
        #expect(result.text == "Hola")
    }

    @Test func servicioRealRechazaSinConexionAntesDeIntentar() async {
        let service = AppleTranslationService(availability: MockLanguageAvailability(overrides: [.french: .needsDownload]))
        await #expect(throws: TranslationServiceError.offlineResourceMissing(.spanish, .french)) {
            _ = try await service.translate("Hola", from: .spanish, to: .french, mode: .offline)
        }
    }

    // MARK: Apple Translation (consulta real)

    /// Consulta a iOS los 30 pares. No falla por el resultado (depende del
    /// dispositivo); lo imprime en el registro como evidencia.
    @Test(.timeLimit(.minutes(2)))
    func matrizRealDeDisponibilidad() async {
        let supported = await LanguageAvailability().supportedLanguages
        let codes = supported.map { $0.minimalIdentifier }.sorted()
        print("DISPONIBILIDAD idiomas admitidos por Translation (\(codes.count)): \(codes.joined(separator: ", "))")

        let service = AppleLanguageAvailabilityService()
        for source in AppLanguage.allCases {
            for target in AppLanguage.allCases where target != source {
                let status = await service.availability(from: source, to: target)
                print("DISPONIBILIDAD \(source.translationCode) → \(target.translationCode): \(status)")
            }
        }
    }
}
