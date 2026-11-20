//
//  AppleSpeechSynthesizer.swift
//  VozTranslate 360 — Atlas Business
//
//  Lectura en voz alta con AVSpeechSynthesizer (siempre local).
//  Usa la voz elegida por el usuario o, si no eligió, la mejor instalada
//  de cualquier variante regional: premium > mejorada > estándar.
//  (Las voces de Siri no están disponibles para apps de terceros.)
//

import AVFoundation

@MainActor
final class AppleSpeechSynthesizer: NSObject, SpeechSynthesizing {

    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?
    private var currentUtteranceID: ObjectIdentifier?
    private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func availableVoices(for language: AppLanguage) -> [VoiceOption] {
        VoiceRanking.candidates(among: VoiceSelector.installedVoices(), for: language,
                                defaultIdentifier: VoiceSelector.systemDefaultIdentifier(for: language))
    }

    func speak(_ text: String, language: AppLanguage, rate: Double, voiceIdentifier: String?) async {
        finishCurrent()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = VoiceSelector.bestVoice(for: language, preferredIdentifier: voiceIdentifier)
        let minimum = Double(AVSpeechUtteranceMinimumSpeechRate)
        let maximum = Double(AVSpeechUtteranceMaximumSpeechRate)
        utterance.rate = Float(min(max(rate, minimum), maximum))

        try? AudioSessionManager.activateForConversation()
        isSpeaking = true
        currentUtteranceID = ObjectIdentifier(utterance)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.continuation = continuation
            synthesizer.speak(utterance)
        }

        isSpeaking = false
        AudioSessionManager.deactivate()
    }

    func stopSpeaking() {
        finishCurrent()
    }

    private func finishCurrent() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        resume(utteranceID: currentUtteranceID)
    }

    /// Reanuda a quien espera en `speak` solo si es la frase actual
    /// (evita que un aviso tardío de la frase anterior corte la nueva).
    fileprivate func resume(utteranceID: ObjectIdentifier?) {
        guard let utteranceID, utteranceID == currentUtteranceID, let continuation else { return }
        self.continuation = nil
        currentUtteranceID = nil
        continuation.resume()
    }
}

extension AppleSpeechSynthesizer: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.resume(utteranceID: id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.resume(utteranceID: id) }
    }
}

// MARK: - Selección de voz

nonisolated enum VoiceSelector {

    /// Voces instaladas (sin voces «novedad» ni personales).
    static func installedVoices() -> [VoiceOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { !$0.voiceTraits.contains(.isNoveltyVoice) && !$0.voiceTraits.contains(.isPersonalVoice) }
            .map { voice in
                VoiceOption(id: voice.identifier,
                            name: voice.name,
                            languageCode: voice.language,
                            quality: VoiceQuality(rawValue: voice.quality.rawValue) ?? .standard)
            }
    }

    /// Voz que iOS usa por defecto para el idioma (suele ser la más natural
    /// entre las estándar, p. ej. Samantha en inglés).
    static func systemDefaultIdentifier(for language: AppLanguage) -> String? {
        AVSpeechSynthesisVoice(language: language.voiceLanguageCode)?.identifier
    }

    /// Voz elegida (si sigue instalada y es del idioma) o la mejor disponible.
    static func bestVoice(for language: AppLanguage, preferredIdentifier: String? = nil) -> AVSpeechSynthesisVoice? {
        let prefix = String(language.voiceLanguageCode.prefix(2))
        if let preferredIdentifier,
           let chosen = AVSpeechSynthesisVoice(identifier: preferredIdentifier),
           chosen.language.hasPrefix(prefix) {
            return chosen
        }
        if let best = VoiceRanking.best(among: installedVoices(), for: language,
                                        defaultIdentifier: systemDefaultIdentifier(for: language)),
           let voice = AVSpeechSynthesisVoice(identifier: best.id) {
            return voice
        }
        return AVSpeechSynthesisVoice(language: language.voiceLanguageCode)
    }
}
