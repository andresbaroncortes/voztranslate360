//
//  ConversationViewModelTests.swift
//  VozTranslate 360 — Atlas Business
//
//  Pruebas automáticas de la Fase 1 (Swift Testing). Validan el flujo
//  escuchar → traducir → leer con los servicios simulados.
//

import Foundation
import Testing
@testable import VozTranslate360

@MainActor
struct ConversationViewModelTests {

    // MARK: Utilidades

    /// Ajustes en un almacén aislado para no tocar los del simulador.
    private func makeSettings(autoSpeak: Bool = false) -> AppSettings {
        let defaults = UserDefaults(suiteName: "tests.\(UUID().uuidString)")!
        let settings = AppSettings(defaults: defaults)
        settings.autoSpeak = autoSpeak
        return settings
    }

    private func makeViewModel(autoSpeak: Bool = false) -> ConversationViewModel {
        ConversationViewModel(dependencies: .mock(), settings: makeSettings(autoSpeak: autoSpeak))
    }

    /// Espera hasta que se cumpla la condición o se agote el tiempo.
    private func waitUntil(timeout: Duration = .seconds(10), _ condition: () -> Bool) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return condition()
    }

    // MARK: Idiomas

    @Test func idiomasPorDefecto() {
        let viewModel = makeViewModel()
        #expect(viewModel.sourceLanguage == .spanish)
        #expect(viewModel.targetLanguage == .english)
    }

    @Test func intercambiarIdiomas() {
        let viewModel = makeViewModel()
        viewModel.swapLanguages()
        #expect(viewModel.sourceLanguage == .english)
        #expect(viewModel.targetLanguage == .spanish)
    }

    @Test func elegirElMismoIdiomaDelOtroLadoLosIntercambia() {
        let viewModel = makeViewModel()
        viewModel.select(.english, for: .source)
        #expect(viewModel.sourceLanguage == .english)
        #expect(viewModel.targetLanguage == .spanish)
    }

    @Test func elegirOtroIdiomaSoloCambiaEseLado() {
        let viewModel = makeViewModel()
        viewModel.select(.french, for: .target)
        #expect(viewModel.sourceLanguage == .spanish)
        #expect(viewModel.targetLanguage == .french)
    }

    @Test func noSeCambianIdiomasMientrasSeEscucha() {
        let viewModel = makeViewModel()
        viewModel.toggleListening(for: .me)
        viewModel.swapLanguages()
        #expect(viewModel.sourceLanguage == .spanish)
        viewModel.stopAll()
    }

    // MARK: Flujo de conversación

    @Test func miTurnoTraduceDeOrigenADestino() async throws {
        let viewModel = makeViewModel()
        viewModel.toggleListening(for: .me)
        #expect(viewModel.phase == .listening(.me))

        let finished = await waitUntil { viewModel.turns.count == 1 && viewModel.phase == .idle }
        #expect(finished)

        let turn = try #require(viewModel.turns.first)
        #expect(turn.speaker == .me)
        #expect(turn.originalText == AppLanguage.spanish.samplePhrase)
        #expect(turn.translatedText == AppLanguage.english.samplePhrase)
    }

    @Test func turnoDeLaOtraPersonaTraduceEnSentidoInverso() async throws {
        let viewModel = makeViewModel()
        viewModel.toggleListening(for: .partner)

        let finished = await waitUntil { viewModel.turns.count == 1 && viewModel.phase == .idle }
        #expect(finished)

        let turn = try #require(viewModel.turns.first)
        #expect(turn.speaker == .partner)
        #expect(turn.sourceLanguage == .english)
        #expect(turn.targetLanguage == .spanish)
        #expect(turn.translatedText == AppLanguage.spanish.samplePhrase)
    }

    @Test func soloUnMicrofonoALaVez() {
        let viewModel = makeViewModel()
        viewModel.toggleListening(for: .me)
        #expect(viewModel.canUseMicrophone(.me))
        #expect(!viewModel.canUseMicrophone(.partner))
        viewModel.toggleListening(for: .partner)
        #expect(viewModel.phase == .listening(.me))
        viewModel.stopAll()
    }

    @Test func detenerAntesDeTerminarTraduceLoOido() async throws {
        let viewModel = makeViewModel()
        viewModel.toggleListening(for: .me)

        let heardSomething = await waitUntil { !viewModel.liveTranscript.isEmpty }
        #expect(heardSomething)
        viewModel.toggleListening(for: .me) // segundo toque = terminar frase

        let finished = await waitUntil { viewModel.turns.count == 1 && viewModel.phase == .idle }
        #expect(finished)
        let turn = try #require(viewModel.turns.first)
        #expect(!turn.originalText.isEmpty)
        #expect(turn.originalText != AppLanguage.spanish.samplePhrase)
    }

    @Test func detenerTodoCancelaSinCrearTurnos() async {
        let viewModel = makeViewModel()
        viewModel.toggleListening(for: .me)
        try? await Task.sleep(for: .milliseconds(400))

        viewModel.stopAll()
        #expect(viewModel.phase == .idle)
        #expect(viewModel.liveTranscript.isEmpty)

        try? await Task.sleep(for: .seconds(3))
        #expect(viewModel.turns.isEmpty)
        #expect(viewModel.phase == .idle)
    }

    @Test func conLecturaEnVozAltaPasaPorFaseHablando() async {
        let viewModel = makeViewModel(autoSpeak: true)
        viewModel.toggleListening(for: .me)
        let spoke = await waitUntil { viewModel.phase == .speaking }
        #expect(spoke)
        let finished = await waitUntil { viewModel.phase == .idle }
        #expect(finished)
        #expect(viewModel.turns.count == 1)
    }

    @Test func limpiarConversacion() async {
        let viewModel = makeViewModel()
        viewModel.toggleListening(for: .me)
        _ = await waitUntil { viewModel.turns.count == 1 && viewModel.phase == .idle }
        viewModel.clearConversation()
        #expect(viewModel.turns.isEmpty)
    }
}

// MARK: - Ajustes y servicios

@MainActor
struct AppSettingsTests {

    @Test func losAjustesSeConservan() {
        let suite = "tests.\(UUID().uuidString)"
        let first = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        first.processingMode = .offline
        first.sourceLanguage = .german
        first.targetLanguage = .italian
        first.autoSpeak = false

        let second = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        #expect(second.processingMode == .offline)
        #expect(second.sourceLanguage == .german)
        #expect(second.targetLanguage == .italian)
        #expect(second.autoSpeak == false)
    }

    @Test func traduccionSimuladaRechazaTextoVacio() async {
        let service = MockTranslationService()
        await #expect(throws: TranslationServiceError.emptyText) {
            _ = try await service.translate("   ", from: .spanish, to: .english, mode: .automatic)
        }
    }

    @Test(arguments: AppLanguage.allCases)
    func cadaIdiomaTieneCodigosValidos(language: AppLanguage) {
        #expect(!language.translationCode.isEmpty)
        #expect(!language.speechLocaleIdentifier.isEmpty)
        #expect(!language.samplePhrase.isEmpty)
    }
}
