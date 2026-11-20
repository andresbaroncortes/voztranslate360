//
//  AppleSpeechSynthesizer.swift
//  VozTranslate 360 — Atlas Business
//
//  Lectura en voz alta con AVSpeechSynthesizer (siempre local).
//  Elige la mejor voz instalada del idioma: premium > mejorada > estándar.
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

    func speak(_ text: String, language: AppLanguage, rate: Double) async {
        finishCurrent()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = VoiceSelector.bestVoice(for: language)
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

    /// Mejor voz instalada para el idioma (sin voces «novedad» ni personales).
    static func bestVoice(for language: AppLanguage) -> AVSpeechSynthesisVoice? {
        let code = language.voiceLanguageCode
        let voices = AVSpeechSynthesisVoice.speechVoices().filter {
            !$0.voiceTraits.contains(.isNoveltyVoice) && !$0.voiceTraits.contains(.isPersonalVoice)
        }
        let exact = voices.filter { $0.language == code }
        let prefix = String(code.prefix(2))
        let candidates = exact.isEmpty ? voices.filter { $0.language.hasPrefix(prefix) } : exact
        if let best = candidates.max(by: { $0.quality.rawValue < $1.quality.rawValue }) {
            return best
        }
        return AVSpeechSynthesisVoice(language: code)
    }
}
