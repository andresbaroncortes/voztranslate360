//
//  ConversationViewModel.swift
//  VozTranslate 360 — Atlas Business
//
//  Orquesta el flujo: escuchar → reconocer → traducir → leer en voz alta.
//  Solo conoce los protocolos de servicio, nunca los frameworks de Apple.
//

import Foundation
import Observation

@MainActor
@Observable
final class ConversationViewModel {

    /// Estado del flujo de una frase.
    enum Phase: Equatable {
        case idle
        case listening(Speaker)
        case translating(Speaker)
        case speaking
    }

    /// Lado del selector de idiomas.
    enum LanguageSide: String, Identifiable {
        case source, target
        var id: String { rawValue }
    }

    // MARK: Estado observable

    private(set) var turns: [ConversationTurn] = []
    private(set) var phase: Phase = .idle
    private(set) var liveTranscript = ""
    var errorMessage: String?

    // MARK: Dependencias

    private let dependencies: AppDependencies
    private let settings: AppSettings
    @ObservationIgnored private var workTask: Task<Void, Never>?

    init(dependencies: AppDependencies, settings: AppSettings) {
        self.dependencies = dependencies
        self.settings = settings
    }

    // MARK: Idiomas

    var sourceLanguage: AppLanguage { settings.sourceLanguage }
    var targetLanguage: AppLanguage { settings.targetLanguage }

    /// Los idiomas no se cambian mientras se procesa una frase.
    var canChangeLanguages: Bool { phase == .idle }

    func swapLanguages() {
        guard canChangeLanguages else { return }
        (settings.sourceLanguage, settings.targetLanguage) = (settings.targetLanguage, settings.sourceLanguage)
    }

    /// Selecciona un idioma. Si coincide con el del otro lado, los intercambia.
    func select(_ language: AppLanguage, for side: LanguageSide) {
        guard canChangeLanguages else { return }
        switch side {
        case .source:
            if language == settings.targetLanguage { swapLanguages() } else { settings.sourceLanguage = language }
        case .target:
            if language == settings.sourceLanguage { swapLanguages() } else { settings.targetLanguage = language }
        }
    }

    // MARK: Micrófono

    func isListening(_ speaker: Speaker) -> Bool {
        phase == .listening(speaker)
    }

    /// El botón de un hablante está activo si no hay nada en curso o si
    /// es ese mismo hablante quien está grabando (para poder detener).
    func canUseMicrophone(_ speaker: Speaker) -> Bool {
        phase == .idle || phase == .listening(speaker)
    }

    /// Pulsar el micrófono: empieza a escuchar o termina la frase.
    func toggleListening(for speaker: Speaker) {
        if isListening(speaker) {
            dependencies.recognizer.stopRecognition()
            return
        }
        guard phase == .idle else { return }
        startPipeline(for: speaker)
    }

    /// Detiene TODO de inmediato: escucha, traducción y voz.
    func stopAll() {
        workTask?.cancel()
        workTask = nil
        dependencies.recognizer.stopRecognition()
        dependencies.synthesizer.stopSpeaking()
        liveTranscript = ""
        phase = .idle
    }

    func replay(_ turn: ConversationTurn) {
        guard phase == .idle else { return }
        // Se marca antes de crear la tarea para que un doble toque no
        // lance dos lecturas a la vez.
        phase = .speaking
        workTask = Task {
            await dependencies.synthesizer.speak(turn.translatedText, language: turn.targetLanguage, rate: settings.speechRate)
            guard !Task.isCancelled else { return }
            phase = .idle
        }
    }

    func clearConversation() {
        stopAll()
        turns.removeAll()
    }

    #if DEBUG
    /// Solo depuración: conversación de ejemplo para capturas (ver DemoMode).
    func loadDemoConversation() {
        turns = [
            ConversationTurn(speaker: .me, sourceLanguage: .spanish, targetLanguage: .english,
                             originalText: AppLanguage.spanish.samplePhrase,
                             translatedText: AppLanguage.english.samplePhrase,
                             processedOnDevice: true),
            ConversationTurn(speaker: .partner, sourceLanguage: .english, targetLanguage: .spanish,
                             originalText: "It's two blocks away, next to the museum.",
                             translatedText: "Está a dos cuadras, junto al museo.",
                             processedOnDevice: true),
            ConversationTurn(speaker: .me, sourceLanguage: .spanish, targetLanguage: .english,
                             originalText: "¿Cuánto cuesta un billete de ida y vuelta?",
                             translatedText: "How much is a round-trip ticket?",
                             processedOnDevice: true)
        ]
    }
    #endif

    // MARK: Flujo principal

    /// El usuario («me») habla el idioma de origen; la otra persona,
    /// el de destino. Esto hace la conversación bidireccional.
    private func languages(for speaker: Speaker) -> (from: AppLanguage, to: AppLanguage) {
        switch speaker {
        case .me:      (from: settings.sourceLanguage, to: settings.targetLanguage)
        case .partner: (from: settings.targetLanguage, to: settings.sourceLanguage)
        }
    }

    private func startPipeline(for speaker: Speaker) {
        let (from, to) = languages(for: speaker)
        let mode = settings.processingMode
        liveTranscript = ""
        phase = .listening(speaker)

        workTask = Task {
            do {
                // 1. Escuchar
                var finalText = ""
                let stream = dependencies.recognizer.startRecognition(language: from, mode: mode)
                for try await update in stream {
                    liveTranscript = update.text
                    if update.isFinal { finalText = update.text }
                }
                if finalText.isEmpty { finalText = liveTranscript }

                // Si se pulsó «Detener», stopAll() ya restableció el estado.
                guard !Task.isCancelled else { return }

                let text = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else {
                    phase = .idle
                    return
                }

                // 2. Traducir
                phase = .translating(speaker)
                let result = try await dependencies.translator.translate(text, from: from, to: to)
                guard !Task.isCancelled else { return }

                turns.append(ConversationTurn(
                    speaker: speaker,
                    sourceLanguage: from,
                    targetLanguage: to,
                    originalText: text,
                    translatedText: result.text,
                    processedOnDevice: result.processedOnDevice
                ))
                liveTranscript = ""

                // 3. Leer en voz alta
                if settings.autoSpeak {
                    phase = .speaking
                    await dependencies.synthesizer.speak(result.text, language: to, rate: settings.speechRate)
                    guard !Task.isCancelled else { return }
                }
                phase = .idle
            } catch is CancellationError {
                // Cancelado por stopAll(): el estado ya está restablecido.
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                liveTranscript = ""
                phase = .idle
            }
        }
    }
}
