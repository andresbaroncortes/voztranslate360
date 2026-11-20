//
//  AppleSpeechRecognizer.swift
//  VozTranslate 360 — Atlas Business
//
//  Dictado real con Speech (SFSpeechRecognizer) + AVAudioEngine.
//
//  Modo de procesamiento (ver SpeechPolicy):
//  • Sin conexión → exige reconocimiento en el iPhone; si el idioma no lo
//    admite, avisa.
//  • Automático   → en el iPhone si el idioma lo admite; si no, servidor de Apple.
//  • En línea     → servidor de Apple (gratuito, con límites de uso de Apple).
//

import AVFoundation
import Speech

@MainActor
final class AppleSpeechRecognizer: SpeechRecognitionProviding {

    private var engine: SpeechRecognitionEngine?

    // MARK: Permisos

    func requestAuthorization() async -> PermissionStatus {
        switch await Self.requestSpeechAuthorization() {
        case .authorized:    break
        case .denied:        return .denied
        case .restricted:    return .restricted
        case .notDetermined: return .notDetermined
        @unknown default:    return .denied
        }
        let microphoneGranted = await AVAudioApplication.requestRecordPermission()
        return microphoneGranted ? .authorized : .denied
    }

    nonisolated private static func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    // MARK: Dictado

    func startRecognition(language: AppLanguage, mode: ProcessingMode) async throws -> AsyncThrowingStream<RecognitionUpdate, Error> {
        engine?.cancel()
        engine = nil

        guard await requestAuthorization() == .authorized else {
            throw SpeechServiceError.permissionDenied
        }
        guard let recognizer = SFSpeechRecognizer(locale: language.speechLocale) else {
            throw SpeechServiceError.recognizerUnavailable(language)
        }
        let onDevice = try SpeechPolicy.requiresOnDevice(
            mode: mode,
            supportsOnDevice: recognizer.supportsOnDeviceRecognition,
            language: language
        )
        guard recognizer.isAvailable else {
            throw SpeechServiceError.recognizerUnavailable(language)
        }

        do {
            try AudioSessionManager.activateForConversation()
        } catch {
            throw SpeechServiceError.audioUnavailable
        }

        let engine = SpeechRecognitionEngine()
        do {
            let stream = try engine.start(recognizer: recognizer, onDevice: onDevice)
            self.engine = engine
            return stream
        } catch {
            AudioSessionManager.deactivate()
            throw error
        }
    }

    func stopRecognition() {
        engine?.endAudio()
    }
}
