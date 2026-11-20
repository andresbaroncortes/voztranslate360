//
//  SpeechRecognitionEngine.swift
//  VozTranslate 360 — Atlas Business
//
//  Motor de una sesión de dictado: AVAudioEngine capta el micrófono y
//  SFSpeechAudioBufferRecognitionRequest lo transcribe.
//
//  PRIVACIDAD: los búferes de audio solo pasan por memoria hacia el
//  reconocedor. Nunca se escriben en disco ni se conservan.
//
//  Concurrencia: los callbacks de audio y de Speech llegan en hilos del
//  sistema. Por eso esta clase no está en el hilo principal y protege su
//  estado con un candado (NSLock).
//

import AVFoundation
import Speech

nonisolated final class SpeechRecognitionEngine: @unchecked Sendable {

    typealias Continuation = AsyncThrowingStream<RecognitionUpdate, Error>.Continuation

    private let lock = NSLock()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var continuation: Continuation?
    private var lastText = ""
    private var isRunning = false

    /// Empieza a escuchar. Lanza error si el micrófono no está disponible.
    func start(recognizer: SFSpeechRecognizer, onDevice: Bool) throws -> AsyncThrowingStream<RecognitionUpdate, Error> {
        let (stream, continuation) = AsyncThrowingStream<RecognitionUpdate, Error>.makeStream()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = onDevice
        request.addsPunctuation = true
        request.taskHint = .dictation

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw SpeechServiceError.audioUnavailable
        }

        lock.withLock {
            self.request = request
            self.continuation = continuation
            self.lastText = ""
            self.isRunning = true
        }

        // El búfer va directo al reconocedor (append es seguro entre hilos).
        nonisolated(unsafe) let tapRequest = request
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            tapRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            lock.withLock { self.continuation = nil }
            teardown()
            throw SpeechServiceError.audioUnavailable
        }

        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            self?.handle(result: result, error: error)
        }
        lock.withLock { self.task = task }

        continuation.onTermination = { [weak self] _ in
            self?.cancel()
        }
        return stream
    }

    /// El usuario terminó de hablar: se deja de captar audio y se espera
    /// el resultado final del reconocedor.
    func endAudio() {
        stopAudio()
        let request = lock.withLock { self.request }
        request?.endAudio()
    }

    /// Cancela todo de inmediato (botón «Detener» o salida de la app).
    func cancel() {
        let task = lock.withLock { self.task }
        task?.cancel()
        finish(error: nil)
    }

    // MARK: Privado

    private func handle(result: SFSpeechRecognitionResult?, error: Error?) {
        // Si ya terminó, se ignoran callbacks tardíos.
        guard lock.withLock({ continuation != nil }) else { return }

        if let result {
            let text = result.bestTranscription.formattedString
            let continuation = lock.withLock { () -> Continuation? in
                lastText = text
                return self.continuation
            }
            continuation?.yield(RecognitionUpdate(text: text, isFinal: result.isFinal))
            if result.isFinal {
                finish(error: nil)
                return
            }
        }

        if let error {
            let text = lock.withLock { lastText }
            if !text.isEmpty {
                // Hubo texto: se entrega como final y se ignora el error
                // (Speech suele reportar error al cerrar el audio).
                let continuation = lock.withLock { self.continuation }
                continuation?.yield(RecognitionUpdate(text: text, isFinal: true))
                finish(error: nil)
            } else if Self.isBenign(error) {
                finish(error: nil)
            } else {
                finish(error: SpeechServiceError.recognitionFailed(error.localizedDescription))
            }
        }
    }

    private func finish(error: Error?) {
        let continuation = lock.withLock { () -> Continuation? in
            let current = self.continuation
            self.continuation = nil
            return current
        }
        if let error {
            continuation?.finish(throwing: error)
        } else {
            continuation?.finish()
        }
        teardown()
    }

    private func teardown() {
        let wasRunning = lock.withLock { () -> Bool in
            let running = isRunning
            isRunning = false
            request = nil
            task = nil
            return running
        }
        guard wasRunning else { return }
        stopAudio()
        AudioSessionManager.deactivate()
    }

    private func stopAudio() {
        lock.withLock {
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }

    /// Errores habituales que no son fallos: no se detectó voz o se canceló.
    private static func isBenign(_ error: Error) -> Bool {
        let nsError = error as NSError
        let benignCodes: Set<Int> = [1110, 216, 301]
        return (nsError.domain == "kAFAssistantErrorDomain" || nsError.domain == "kLSRErrorDomain")
            && benignCodes.contains(nsError.code)
    }
}
