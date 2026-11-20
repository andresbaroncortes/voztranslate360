//
//  MockServices.swift
//  VozTranslate 360 — Atlas Business
//
//  Servicios SIMULADOS de la Fase 1. Permiten probar toda la interfaz en el
//  simulador sin micrófono, sin permisos y sin modelos de idioma.
//  Se reemplazarán por implementaciones reales en las Fases 2, 3 y 5.
//

import Foundation
import Observation

// MARK: - Traducción simulada

@MainActor
final class MockTranslationService: TranslationProviding {

    func translate(_ text: String, from source: AppLanguage, to target: AppLanguage) async throws -> TranslationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationServiceError.emptyText }

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

    func startRecognition(language: AppLanguage, mode: ProcessingMode) -> AsyncThrowingStream<RecognitionUpdate, Error> {
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

    func speak(_ text: String, language: AppLanguage, rate: Double) async {
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
