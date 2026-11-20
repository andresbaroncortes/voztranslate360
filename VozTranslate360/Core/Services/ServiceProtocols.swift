//
//  ServiceProtocols.swift
//  VozTranslate 360 — Atlas Business
//
//  Contratos de los servicios. La interfaz y los ViewModels dependen SOLO
//  de estos protocolos; así la Fase 1 funciona con servicios simulados y
//  cada fase siguiente sustituye una implementación sin tocar las vistas.
//
//  Implementaciones reales previstas:
//  • TranslationProviding        → Translation framework       (Fase 2)
//  • SpeechRecognitionProviding  → Speech + AVAudioEngine      (Fase 3)
//  • SpeechSynthesizing          → AVSpeechSynthesizer         (Fase 3)
//  • ConnectivityMonitoring      → Network (NWPathMonitor)     (Fase 5)
//

import Foundation

// MARK: - Tipos compartidos

nonisolated enum PermissionStatus: Sendable, Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

/// Fragmento de texto reconocido mientras la persona habla.
nonisolated struct RecognitionUpdate: Sendable, Equatable {
    let text: String
    /// `true` cuando el reconocedor da el resultado por terminado.
    let isFinal: Bool
}

nonisolated struct TranslationResult: Sendable, Equatable {
    let text: String
    let processedOnDevice: Bool
}

nonisolated enum TranslationServiceError: LocalizedError, Equatable {
    case unsupportedPair(AppLanguage, AppLanguage)
    case offlineResourceMissing(AppLanguage)
    case emptyText

    var errorDescription: String? {
        switch self {
        case let .unsupportedPair(from, to):
            "La traducción de \(from.displayName) a \(to.displayName) no está disponible en este iPhone."
        case let .offlineResourceMissing(language):
            "El idioma \(language.displayName) no está instalado para usarse sin conexión."
        case .emptyText:
            "No se detectó texto para traducir."
        }
    }
}

// MARK: - Protocolos

@MainActor
protocol TranslationProviding: AnyObject {
    func translate(_ text: String, from source: AppLanguage, to target: AppLanguage) async throws -> TranslationResult
}

@MainActor
protocol SpeechRecognitionProviding: AnyObject {
    /// Pide permisos de micrófono y reconocimiento de voz.
    func requestAuthorization() async -> PermissionStatus

    /// Inicia la escucha. El flujo emite resultados parciales y termina
    /// con uno final cuando se llama a `stopRecognition()`.
    func startRecognition(language: AppLanguage, mode: ProcessingMode) -> AsyncThrowingStream<RecognitionUpdate, Error>

    /// Detiene la escucha y cierra el flujo con el último texto.
    func stopRecognition()
}

@MainActor
protocol SpeechSynthesizing: AnyObject {
    var isSpeaking: Bool { get }

    /// Lee el texto en voz alta y vuelve cuando termina o se detiene.
    /// - Parameter rate: 0…1 (0,5 = velocidad normal).
    func speak(_ text: String, language: AppLanguage, rate: Double) async

    func stopSpeaking()
}

@MainActor
protocol ConnectivityMonitoring: AnyObject {
    var isConnected: Bool { get }
    /// `true` si la conexión es de datos móviles u otra conexión costosa.
    var isExpensive: Bool { get }
}
