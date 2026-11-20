//
//  Fase4BidirectionalTests.swift
//  VozTranslate 360 — Atlas Business
//
//  Pruebas de la Fase 4: fin de frase por pausa, cierre del micrófono sin
//  voz, turnos automáticos y textos en el idioma de la otra persona.
//

import Foundation
import Testing
@testable import VozTranslate360

/// Reconocedor guionizado: emite parciales y luego queda en silencio
/// hasta que se llame a `stopRecognition()`.
@MainActor
private final class ScriptedRecognizer: SpeechRecognitionProviding {
    private let partials: [String]
    private var continuation: AsyncThrowingStream<RecognitionUpdate, Error>.Continuation?
    private var lastText = ""
    private(set) var startedLanguages: [AppLanguage] = []

    init(partials: [String]) { self.partials = partials }

    func requestAuthorization() async -> PermissionStatus { .authorized }

    func startRecognition(language: AppLanguage, mode: ProcessingMode) async throws -> AsyncThrowingStream<RecognitionUpdate, Error> {
        startedLanguages.append(language)
        let (stream, continuation) = AsyncThrowingStream<RecognitionUpdate, Error>.makeStream()
        self.continuation = continuation
        lastText = ""
        for text in partials {
            lastText = text
            continuation.yield(RecognitionUpdate(text: text, isFinal: false))
        }
        return stream
    }

    func stopRecognition() {
        continuation?.yield(RecognitionUpdate(text: lastText, isFinal: true))
        continuation?.finish()
        continuation = nil
    }
}

@MainActor
struct Fase4BidirectionalTests {

    private func makeSettings(autoEndOnPause: Bool = true, autoTurnTaking: Bool = false) -> AppSettings {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "tests.\(UUID().uuidString)")!)
        settings.autoSpeak = false
        settings.autoEndOnPause = autoEndOnPause
        settings.autoTurnTaking = autoTurnTaking
        return settings
    }

    private func makeViewModel(recognizer: any SpeechRecognitionProviding,
                               settings: AppSettings) -> ConversationViewModel {
        let mock = AppDependencies.mock()
        let dependencies = AppDependencies(translator: mock.translator, availability: mock.availability,
                                           recognizer: recognizer, synthesizer: mock.synthesizer,
                                           connectivity: mock.connectivity)
        let viewModel = ConversationViewModel(dependencies: dependencies, settings: settings)
        viewModel.pauseDuration = .milliseconds(300)
        viewModel.noSpeechTimeout = .milliseconds(500)
        return viewModel
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

    // MARK: Pausas

    @Test func laPausaTerminaLaFrase() async throws {
        let viewModel = makeViewModel(recognizer: ScriptedRecognizer(partials: ["Buenos", "Buenos días"]),
                                      settings: makeSettings())
        viewModel.toggleListening(for: .me)

        let finished = await waitUntil { viewModel.turns.count == 1 && viewModel.phase == .idle }
        #expect(finished)
        let turn = try #require(viewModel.turns.first)
        #expect(turn.originalText == "Buenos días")
    }

    @Test func sinPausaAutomaticaEsperaAlUsuario() async {
        let viewModel = makeViewModel(recognizer: ScriptedRecognizer(partials: ["Hola"]),
                                      settings: makeSettings(autoEndOnPause: false))
        viewModel.toggleListening(for: .me)
        try? await Task.sleep(for: .milliseconds(900))
        #expect(viewModel.phase == .listening(.me))

        viewModel.toggleListening(for: .me) // el usuario termina la frase
        let finished = await waitUntil { viewModel.turns.count == 1 && viewModel.phase == .idle }
        #expect(finished)
    }

    @Test func sinVozSeCierraElMicrofono() async {
        let viewModel = makeViewModel(recognizer: ScriptedRecognizer(partials: []),
                                      settings: makeSettings())
        viewModel.toggleListening(for: .me)

        let closed = await waitUntil(timeout: .seconds(3)) { viewModel.phase == .idle }
        #expect(closed)
        #expect(viewModel.turns.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: Turnos automáticos

    @Test func turnosAutomaticosEscuchanALaOtraPersona() async {
        let recognizer = ScriptedRecognizer(partials: ["Hola"])
        let viewModel = makeViewModel(recognizer: recognizer, settings: makeSettings(autoTurnTaking: true))
        viewModel.toggleListening(for: .me)

        let partnerTurn = await waitUntil { viewModel.phase == .listening(.partner) }
        #expect(partnerTurn)
        #expect(viewModel.turns.count == 1)

        let secondTurn = await waitUntil { viewModel.turns.count == 2 }
        #expect(secondTurn)
        #expect(viewModel.turns.last?.speaker == .partner)
        // Español (yo) y luego inglés (la otra persona).
        #expect(Array(recognizer.startedLanguages.prefix(2)) == [.spanish, .english])
        viewModel.stopAll()
        #expect(viewModel.phase == .idle)
    }

    @Test func sinTurnosAutomaticosVuelveAReposo() async {
        let viewModel = makeViewModel(recognizer: ScriptedRecognizer(partials: ["Hola"]),
                                      settings: makeSettings(autoTurnTaking: false))
        viewModel.toggleListening(for: .me)
        let finished = await waitUntil { viewModel.turns.count == 1 && viewModel.phase == .idle }
        #expect(finished)
        try? await Task.sleep(for: .milliseconds(500))
        #expect(viewModel.phase == .idle)
    }

    @Test func textoEscritoNoActivaTurnosAutomaticos() async {
        let viewModel = makeViewModel(recognizer: ScriptedRecognizer(partials: ["Hola"]),
                                      settings: makeSettings(autoTurnTaking: true))
        viewModel.translateTyped("Hola")
        let finished = await waitUntil { viewModel.turns.count == 1 && viewModel.phase == .idle }
        #expect(finished)
        try? await Task.sleep(for: .milliseconds(400))
        #expect(viewModel.phase == .idle)
    }

    // MARK: Modelo

    @Test func elOtroHablante() {
        #expect(Speaker.me.other == .partner)
        #expect(Speaker.partner.other == .me)
    }

    @Test(arguments: AppLanguage.allCases)
    func textosParaLaOtraPersona(language: AppLanguage) {
        #expect(!language.speakLabel.isEmpty)
        #expect(!language.tapToSpeakPrompt.isEmpty)
        #expect(!language.listeningLabel.isEmpty)
    }

    @Test func losAjustesDeConversacionSeConservan() {
        let suite = "tests.\(UUID().uuidString)"
        let first = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        #expect(first.autoEndOnPause)
        #expect(!first.autoTurnTaking)
        first.autoEndOnPause = false
        first.autoTurnTaking = true
        let second = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        #expect(!second.autoEndOnPause)
        #expect(second.autoTurnTaking)
    }
}
