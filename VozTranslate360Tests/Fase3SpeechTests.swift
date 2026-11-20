//
//  Fase3SpeechTests.swift
//  VozTranslate 360 — Atlas Business
//
//  Pruebas de la Fase 3: reglas de dictado por modo, errores de permisos,
//  «terminar frase» durante el arranque y consulta real de dictado y voces.
//

import AVFoundation
import Foundation
@preconcurrency import Speech
import Testing
@testable import VozTranslate360

/// Reconocedor que falla al arrancar (p. ej. permisos negados).
@MainActor
private final class FailingRecognizer: SpeechRecognitionProviding {
    let error: SpeechServiceError
    init(error: SpeechServiceError) { self.error = error }
    func requestAuthorization() async -> PermissionStatus { .denied }
    func startRecognition(language: AppLanguage, locale: Locale, mode: ProcessingMode) async throws -> AsyncThrowingStream<RecognitionUpdate, Error> {
        throw error
    }
    func stopRecognition() {}
    func supportsOnDeviceDictation(for locale: Locale) -> Bool { false }
    func dictationLocales(for language: AppLanguage) -> [Locale] { [language.speechLocale] }
}

/// Reconocedor lento al arrancar (simula el diálogo de permisos).
@MainActor
private final class SlowStartRecognizer: SpeechRecognitionProviding {
    private var continuation: AsyncThrowingStream<RecognitionUpdate, Error>.Continuation?
    private(set) var stopCalls = 0
    func supportsOnDeviceDictation(for locale: Locale) -> Bool { true }
    func dictationLocales(for language: AppLanguage) -> [Locale] { [language.speechLocale] }
    func requestAuthorization() async -> PermissionStatus { .authorized }
    func startRecognition(language: AppLanguage, locale: Locale, mode: ProcessingMode) async throws -> AsyncThrowingStream<RecognitionUpdate, Error> {
        try await Task.sleep(for: .milliseconds(300))
        let (stream, continuation) = AsyncThrowingStream<RecognitionUpdate, Error>.makeStream()
        self.continuation = continuation
        continuation.yield(RecognitionUpdate(text: "Hola", isFinal: false))
        return stream
    }
    func stopRecognition() {
        stopCalls += 1
        continuation?.yield(RecognitionUpdate(text: "Hola", isFinal: true))
        continuation?.finish()
        continuation = nil
    }
}

@MainActor
struct Fase3SpeechTests {

    private func makeSettings() -> AppSettings {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "tests.\(UUID().uuidString)")!)
        settings.autoSpeak = false
        return settings
    }

    private func dependencies(recognizer: any SpeechRecognitionProviding) -> AppDependencies {
        let mock = AppDependencies.mock()
        return AppDependencies(translator: mock.translator, availability: mock.availability,
                               recognizer: recognizer, synthesizer: mock.synthesizer,
                               connectivity: mock.connectivity)
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

    // MARK: Reglas de dictado

    @Test func sinConexionExigeDictadoEnElDispositivo() throws {
        #expect(try SpeechPolicy.requiresOnDevice(mode: .offline, supportsOnDevice: true, language: .spanish))
        #expect(throws: SpeechServiceError.onDeviceUnavailable(.italian)) {
            try SpeechPolicy.requiresOnDevice(mode: .offline, supportsOnDevice: false, language: .italian)
        }
    }

    @Test func automaticoPriorizaElDispositivo() throws {
        #expect(try SpeechPolicy.requiresOnDevice(mode: .automatic, supportsOnDevice: true, language: .spanish))
        #expect(try !SpeechPolicy.requiresOnDevice(mode: .automatic, supportsOnDevice: false, language: .spanish))
    }

    @Test func enLineaUsaElServidor() throws {
        #expect(try !SpeechPolicy.requiresOnDevice(mode: .online, supportsOnDevice: true, language: .spanish))
    }

    // MARK: Errores y permisos

    @Test func permisoNegadoOfreceAbrirAjustes() async {
        let viewModel = ConversationViewModel(
            dependencies: dependencies(recognizer: FailingRecognizer(error: .permissionDenied)),
            settings: makeSettings()
        )
        viewModel.toggleListening(for: .me)
        let finished = await waitUntil { viewModel.errorMessage != nil }
        #expect(finished)
        #expect(viewModel.errorOffersSettings)
        #expect(viewModel.phase == .idle)
    }

    @Test func otrosErroresNoOfrecenAjustes() async {
        let viewModel = ConversationViewModel(
            dependencies: dependencies(recognizer: FailingRecognizer(error: .onDeviceUnavailable(.german))),
            settings: makeSettings()
        )
        viewModel.toggleListening(for: .partner)
        let finished = await waitUntil { viewModel.errorMessage != nil }
        #expect(finished)
        #expect(!viewModel.errorOffersSettings)
        #expect(viewModel.errorMessage == SpeechServiceError.onDeviceUnavailable(.german).errorDescription)
    }

    @Test func terminarFraseMientrasArrancaElMicrofono() async throws {
        let recognizer = SlowStartRecognizer()
        let viewModel = ConversationViewModel(dependencies: dependencies(recognizer: recognizer), settings: makeSettings())
        viewModel.toggleListening(for: .me)
        viewModel.toggleListening(for: .me) // segundo toque antes de que arranque

        let finished = await waitUntil { viewModel.turns.count == 1 && viewModel.phase == .idle }
        #expect(finished)
        #expect(recognizer.stopCalls >= 1)
        let turn = try #require(viewModel.turns.first)
        #expect(turn.originalText == "Hola")
    }

    @Test func detenerTodoDuranteElArranqueNoTraduce() async {
        let recognizer = SlowStartRecognizer()
        let viewModel = ConversationViewModel(dependencies: dependencies(recognizer: recognizer), settings: makeSettings())
        viewModel.toggleListening(for: .me)
        viewModel.stopAll()
        try? await Task.sleep(for: .seconds(1))
        #expect(viewModel.turns.isEmpty)
        #expect(viewModel.phase == .idle)
    }

    // MARK: Consulta real (evidencia en el registro)

    @Test func dictadoYVocesDisponibles() {
        for language in AppLanguage.allCases {
            let recognizer = SFSpeechRecognizer(locale: language.speechLocale)
            let dictation = recognizer.map {
                "disponible=\($0.isAvailable), enDispositivo=\($0.supportsOnDeviceRecognition)"
            } ?? "sin reconocedor"
            print("DICTADO \(language.speechLocaleIdentifier): \(dictation)")

            if let voice = VoiceSelector.bestVoice(for: language) {
                print("VOZ \(language.voiceLanguageCode): \(voice.name) [\(voice.language)] calidad=\(voice.quality.rawValue)")
            } else {
                print("VOZ \(language.voiceLanguageCode): ninguna instalada")
            }
        }
    }
}
