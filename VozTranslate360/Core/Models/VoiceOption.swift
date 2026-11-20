//
//  VoiceOption.swift
//  VozTranslate 360 — Atlas Business
//
//  Descripción de una voz instalada en el iPhone, independiente de
//  AVFoundation (para la interfaz y las pruebas).
//

import Foundation

nonisolated enum VoiceQuality: Int, Comparable, Sendable, CaseIterable {
    case standard = 1
    case enhanced = 2
    case premium = 3

    var label: String {
        switch self {
        case .standard: "Estándar"
        case .enhanced: "Mejorada"
        case .premium:  "Premium"
        }
    }

    static func < (lhs: VoiceQuality, rhs: VoiceQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

nonisolated struct VoiceOption: Identifiable, Hashable, Sendable {
    /// Identificador de AVSpeechSynthesisVoice.
    let id: String
    let name: String
    /// Código BCP-47 de la voz, p. ej. "es-MX".
    let languageCode: String
    let quality: VoiceQuality

    /// Nombre legible de la variante regional («español (México)»).
    var regionName: String {
        Locale(identifier: "es").localizedString(forIdentifier: languageCode) ?? languageCode
    }
}

/// Elección de la voz más natural disponible.
nonisolated enum VoiceRanking {

    /// Mejor voz para el idioma: primero la calidad (premium > mejorada >
    /// estándar), luego la variante regional por defecto y luego el nombre.
    /// Considera TODAS las variantes regionales del idioma (es-ES, es-MX…).
    static func best(among voices: [VoiceOption], for language: AppLanguage) -> VoiceOption? {
        candidates(among: voices, for: language).first
    }

    /// Voces del idioma ordenadas de mejor a peor.
    static func candidates(among voices: [VoiceOption], for language: AppLanguage) -> [VoiceOption] {
        let preferredCode = language.voiceLanguageCode
        let prefix = String(preferredCode.prefix(2))
        return voices
            .filter { $0.languageCode.hasPrefix(prefix) }
            .sorted { lhs, rhs in
                if lhs.quality != rhs.quality { return lhs.quality > rhs.quality }
                let lhsExact = lhs.languageCode == preferredCode
                let rhsExact = rhs.languageCode == preferredCode
                if lhsExact != rhsExact { return lhsExact }
                return lhs.name < rhs.name
            }
    }
}
