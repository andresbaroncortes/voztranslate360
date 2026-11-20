//
//  ServiceProtocols.swift
//  VozTranslate 360 — Atlas Business
//
//  Contratos de los servicios. La interfaz y los ViewModels dependen SOLO
//  de estos protocolos; cada fase sustituye una implementación simulada
//  por la real sin tocar las vistas.
//
//  Implementaciones:
//  • TranslationProviding          → Translation framework       (Fase 2 ✔)
//  • LanguageAvailabilityChecking  → Translation.LanguageAvailability (Fase 2 ✔)
//  • SpeechRecognitionProviding    → Speech + AVAudioEngine      (Fase 3)
//  • SpeechSynthesizing            → AVSpeechSynthesizer         (Fase 3)
//  • ConnectivityMonitoring        → Network (NWPathMonitor)     (Fase 5)
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

/// Estado de un par de idiomas según iOS (no supuesto por la app).
nonisolated enum PairAvailability: Sendable, Equatable {
    /// Modelos instalados: traduce sin conexión.
    case installed
    /// iOS lo admite, pero hay que descargar los modelos (requiere conexión).
    case needsDownload
    /// iOS no admite este par.
    case unsupported
}

nonisolated enum TranslationServiceError: LocalizedError, Equatable {
    case unsupportedPair(AppLanguage, AppLanguage)
    case offlineResourceMissing(AppLanguage, AppLanguage)
    case translationFailed(String)
    case emptyText

    var errorDescription: String? {
        switch self {
        case let .unsupportedPair(from, to):
            "iOS no ofrece traducción de \(from.displayName) a \(to.displayName)."
        case let .offlineResourceMissing(from, to):
            "\(from.displayName) → \(to.displayName) no está descargado para usarse sin conexión. Cambia el modo a «Automático» con conexión para descargarlo, o descárgalo en Ajustes ▸ Apps ▸ Traducir ▸ Idiomas descargados."
        case let .translationFailed(reason):
            "No se pudo traducir. \(reason)"
        case .emptyText:
            "No se detectó texto para traducir."
        }
    }
}

/// Reglas comunes para decidir si una traducción puede hacerse en el modo
/// elegido. La usan el servicio real y el simulado.
nonisolated enum TranslationPolicy {
    static func validate(_ availability: PairAvailability,
                         from source: AppLanguage,
                         to target: AppLanguage,
                         mode: ProcessingMode) throws {
        switch availability {
        case .unsupported:
            throw TranslationServiceError.unsupportedPair(source, target)
        case .needsDownload:
            // Sin conexión no se puede descargar: se avisa en vez de intentarlo.
            if mode == .offline {
                throw TranslationServiceError.offlineResourceMissing(source, target)
            }
        case .installed:
            break
        }
    }
}

// MARK: - Protocolos

@MainActor
protocol TranslationProviding: AnyObject {
    func translate(_ text: String,
                   from source: AppLanguage,
                   to target: AppLanguage,
                   mode: ProcessingMode) async throws -> TranslationResult
}

@MainActor
protocol LanguageAvailabilityChecking: AnyObject {
    func availability(from source: AppLanguage, to target: AppLanguage) async -> PairAvailability
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
