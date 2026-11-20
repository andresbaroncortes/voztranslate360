//
//  MockServices.swift
//  VozTranslate 360 — Atlas Business
//
//  Servicios SIMULADOS. Se usan en las pruebas automáticas, en las capturas
//  (modo demostración) y, hasta la Fase 3, para el dictado y la voz.
//

import Foundation
import Observation

// MARK: - Disponibilidad simulada

@MainActor
final class MockLanguageAvailability: LanguageAvailabilityChecking {
    /// Estado forzado por idioma (si aparece como origen o destino).
    /// Lo que no esté aquí se considera instalado.
    var overrides: [AppLanguage: PairAvailability]

    init(overrides: [AppLanguage: PairAvailability] = [:]) {
        self.overrides = overrides
    }

    func availability(from source: AppLanguage, to target: AppLanguage) async -> PairAvailability {
        overrides[source] ?? overrides[target] ?? .installed
    }
}

// MARK: - Traducción simulada

@MainActor
final class MockTranslationService: TranslationProviding {

    private let availability: any LanguageAvailabilityChecking
    private let connectivity: any ConnectivityMonitoring

    init(availability: any LanguageAvailabilityChecking = MockLanguageAvailability(),
         connectivity: any ConnectivityMonitoring = MockConnectivityMonitor()) {
        self.availability = availability
        self.connectivity = connectivity
    }

    /// Simula la descarga: el par pasa a «instalado».
    func prepare(from source: AppLanguage, to target: AppLanguage) async throws {
        let status = await availability.availability(from: source, to: target)
        if status == .unsupported { throw TranslationServiceError.unsupportedPair(source, target) }
        guard status == .needsDownload else { return }
        guard connectivity.isConnected else {
            throw TranslationServiceError.downloadRequiresConnection(source, target)
        }
        try await Task.sleep(for: .milliseconds(300))
        if let mock = availability as? MockLanguageAvailability {
            mock.overrides[source] = nil
            mock.overrides[target] = nil
        }
    }

    func translate(_ text: String,
                   from source: AppLanguage,
                   to target: AppLanguage,
                   mode: ProcessingMode) async throws -> TranslationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationServiceError.emptyText }

        // Mismas reglas que el servicio real.
        let status = await availability.availability(from: source, to: target)
        try TranslationPolicy.validate(status, from: source, to: target, mode: mode,
                                       isConnected: connectivity.isConnected)

        // Simula el tiempo de inferencia del modelo local.
        try await Task.sleep(for: .milliseconds(450))

        // Si es la frase de ejemplo, devuelve su versión real en el otro idioma.
        if trimmed == source.samplePhrase {
            return TranslationResult(text: target.samplePhrase, processedOnDevice: true)
        }
        return TranslationResult(text: "[\(target.translationCode)] \(trimmed)", processedOnDevice: true)
    }
}

// MARK: - Reconocimiento simulado

@MainActor
final class MockSpeechRecognizer: SpeechRecognitionProviding {

    private var continuation: AsyncThrowingStream<RecognitionUpdate, Error>.Continuation?
    private var emitTask: Task<Void, Never>?
    private var partialText = ""

    func requestAuthorization() async -> PermissionStatus { .authorized }

    /// Idiomas sin dictado local simulados (para pruebas y capturas).
    var languagesWithoutOnDevice: Set<AppLanguage> = []

    func supportsOnDeviceDictation(for locale: Locale) -> Bool {
        !languagesWithoutOnDevice.contains { locale.identifier.hasPrefix(String($0.speechLocaleIdentifier.prefix(2))) }
    }

    func dictationLocales(for language: AppLanguage) -> [Locale] {
        [language.speechLocale]
    }

    func startRecognition(language: AppLanguage, locale: Locale, mode: ProcessingMode) async throws -> AsyncThrowingStream<RecognitionUpdate, Error> {
        cancelCurrent()

        let (stream, continuation) = AsyncThrowingStream<RecognitionUpdate, Error>.makeStream()
        self.continuation = continuation
        partialText = ""

        let words = language.samplePhrase.split(separator: " ").map(String.init)

        // Emite la frase palabra por palabra, como un dictado real.
        let task = Task { [weak self] in
            for word in words {
                try? await Task.sleep(for: .milliseconds(320))
                guard !Task.isCancelled, let self else { return }
                self.partialText = self.partialText.isEmpty ? word : self.partialText + " " + word
                self.continuation?.yield(RecognitionUpdate(text: self.partialText, isFinal: false))
            }
            self?.finishStream()
        }
        emitTask = task
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    func stopRecognition() {
        emitTask?.cancel()
        emitTask = nil
        finishStream()
    }

    private func finishStream() {
        continuation?.yield(RecognitionUpdate(text: partialText, isFinal: true))
        continuation?.finish()
        continuation = nil
    }

    private func cancelCurrent() {
        emitTask?.cancel()
        emitTask = nil
        continuation?.finish()
        continuation = nil
    }
}

// MARK: - Voz simulada

@MainActor
final class MockSpeechSynthesizer: SpeechSynthesizing {

    private(set) var isSpeaking = false

    func availableVoices(for language: AppLanguage) -> [VoiceOption] {
        let code = language.voiceLanguageCode
        return [
            VoiceOption(id: "mock.premium.\(code)", name: "Voz natural", languageCode: code, quality: .premium),
            VoiceOption(id: "mock.standard.\(code)", name: "Voz básica", languageCode: code, quality: .standard)
        ]
    }

    func speak(_ text: String, language: AppLanguage, rate: Double, voiceIdentifier: String?) async {
        isSpeaking = true
        defer { isSpeaking = false }
        // Duración aproximada según la longitud del texto.
        let milliseconds = min(3_000, max(600, text.count * 55))
        try? await Task.sleep(for: .milliseconds(milliseconds))
    }

    func stopSpeaking() {
        isSpeaking = false
    }
}

// MARK: - Conectividad simulada

@MainActor
@Observable
final class MockConnectivityMonitor: ConnectivityMonitoring {
    var isConnected: Bool
    var isExpensive: Bool

    init(isConnected: Bool = true, isExpensive: Bool = false) {
        self.isConnected = isConnected
        self.isExpensive = isExpensive
    }
}
