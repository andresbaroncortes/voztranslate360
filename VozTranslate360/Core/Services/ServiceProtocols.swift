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
//  • SpeechRecognitionProviding    → Speech + AVAudioEngine      (Fase 3 ✔)
//  • SpeechSynthesizing            → AVSpeechSynthesizer         (Fase 3 ✔)
//  • ConnectivityMonitoring        → Network (NWPathMonitor)     (Fase 5 ✔)
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
    case downloadRequiresConnection(AppLanguage, AppLanguage)
    case translationFailed(String)
    case emptyText

    var errorDescription: String? {
        switch self {
        case let .unsupportedPair(from, to):
            "iOS no ofrece traducción de \(from.displayName) a \(to.displayName)."
        case let .offlineResourceMissing(from, to):
            "\(from.displayName) → \(to.displayName) no está descargado para usarse sin conexión. Con conexión, descárgalo en Ajustes ▸ Idiomas sin conexión, o cambia el modo a «Automático»."
        case let .downloadRequiresConnection(from, to):
            "Para traducir de \(from.displayName) a \(to.displayName) hay que descargar el idioma una vez, y ahora no hay conexión. Conéctate a internet o elige un idioma instalado (Ajustes ▸ Idiomas sin conexión)."
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
                         mode: ProcessingMode,
                         isConnected: Bool = true) throws {
        switch availability {
        case .unsupported:
            throw TranslationServiceError.unsupportedPair(source, target)
        case .needsDownload:
            // Sin conexión no se puede descargar: se avisa en vez de intentarlo.
            if mode == .offline {
                throw TranslationServiceError.offlineResourceMissing(source, target)
            }
            if !isConnected {
                throw TranslationServiceError.downloadRequiresConnection(source, target)
            }
        case .installed:
            break
        }
    }
}

nonisolated enum SpeechServiceError: LocalizedError, Equatable {
    case permissionDenied
    case recognizerUnavailable(AppLanguage)
    case onDeviceUnavailable(AppLanguage)
    case audioUnavailable
    case recognitionFailed(String)

    /// El usuario debe cambiar un permiso en la app Ajustes de iOS.
    var requiresSettings: Bool { self == .permissionDenied }

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "VozTranslate 360 necesita permiso para usar el micrófono y el reconocimiento de voz. Actívalos en Ajustes."
        case let .recognizerUnavailable(language):
            "El dictado en \(language.displayName) no está disponible ahora. Comprueba la conexión o escribe el texto."
        case let .onDeviceUnavailable(language):
            "El dictado sin conexión en \(language.displayName) no está disponible en este iPhone. Usa el modo «Automático» con conexión o escribe el texto."
        case .audioUnavailable:
            "No se pudo acceder al micrófono. Cierra otras apps que lo estén usando e inténtalo de nuevo."
        case let .recognitionFailed(reason):
            "No se pudo reconocer la voz. \(reason)"
        }
    }
}

/// Decide si el dictado se hace en el iPhone o en los servidores de Apple.
nonisolated enum SpeechPolicy {
    /// - Returns: `true` si debe exigirse el reconocimiento en el dispositivo.
    static func requiresOnDevice(mode: ProcessingMode,
                                 supportsOnDevice: Bool,
                                 language: AppLanguage,
                                 isConnected: Bool = true) throws -> Bool {
        switch mode {
        case .offline:
            guard supportsOnDevice else { throw SpeechServiceError.onDeviceUnavailable(language) }
            return true
        case .automatic:
            // Prioriza lo local; si el idioma no lo admite, usa el servidor
            // (solo si hay conexión).
            if supportsOnDevice { return true }
            guard isConnected else { throw SpeechServiceError.onDeviceUnavailable(language) }
            return false
        case .online:
            // Sin conexión, se recurre al dictado local si existe.
            if isConnected { return false }
            guard supportsOnDevice else { throw SpeechServiceError.recognizerUnavailable(language) }
            return true
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

    /// Descarga (si hace falta) los modelos del par para usarlo sin conexión.
    /// iOS muestra su propia hoja de confirmación y progreso.
    func prepare(from source: AppLanguage, to target: AppLanguage) async throws
}

@MainActor
protocol LanguageAvailabilityChecking: AnyObject {
    func availability(from source: AppLanguage, to target: AppLanguage) async -> PairAvailability
}

@MainActor
protocol SpeechRecognitionProviding: AnyObject {
    /// Pide permisos de micrófono y reconocimiento de voz.
    func requestAuthorization() async -> PermissionStatus

    /// Pide permisos si hace falta e inicia la escucha. El flujo emite
    /// resultados parciales y termina con uno final cuando se llama a
    /// `stopRecognition()`. El audio nunca se guarda.
    func startRecognition(language: AppLanguage, mode: ProcessingMode) async throws -> AsyncThrowingStream<RecognitionUpdate, Error>

    /// Detiene la escucha y cierra el flujo con el último texto.
    func stopRecognition()

    /// `true` si este iPhone puede dictar el idioma sin conexión.
    func supportsOnDeviceDictation(for language: AppLanguage) -> Bool
}

@MainActor
protocol SpeechSynthesizing: AnyObject {
    var isSpeaking: Bool { get }

    /// Lee el texto en voz alta y vuelve cuando termina o se detiene.
    /// - Parameters:
    ///   - rate: 0…1 (0,5 = velocidad normal).
    ///   - voiceIdentifier: voz elegida por el usuario; `nil` = la mejor instalada.
    func speak(_ text: String, language: AppLanguage, rate: Double, voiceIdentifier: String?) async

    /// Voces instaladas para el idioma, de mejor a peor.
    func availableVoices(for language: AppLanguage) -> [VoiceOption]

    func stopSpeaking()
}

@MainActor
protocol ConnectivityMonitoring: AnyObject {
    var isConnected: Bool { get }
    /// `true` si la conexión es de datos móviles u otra conexión costosa.
    var isExpensive: Bool { get }
}
