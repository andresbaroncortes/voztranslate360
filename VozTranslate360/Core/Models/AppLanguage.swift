//
//  AppLanguage.swift
//  VozTranslate 360 — Atlas Business
//
//  Catálogo de idiomas iniciales de la aplicación.
//
//  IMPORTANTE: los códigos de este archivo son los valores que se usarán
//  con cada framework de Apple, pero la disponibilidad REAL (sobre todo la
//  offline) se comprueba en tiempo de ejecución:
//    • Traducción  → LanguageAvailability (Translation, Fase 2 y 5).
//    • Dictado     → SFSpeechRecognizer.supportsOnDeviceRecognition (Fase 3 y 5).
//    • Voz         → AVSpeechSynthesisVoice(language:) (Fase 3).
//  Nunca se debe mostrar «disponible sin conexión» a partir de esta tabla.
//

import Foundation

/// Idiomas que la aplicación ofrece en su primera versión.
nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case spanish
    case english
    case french
    case italian
    case german
    case portuguese

    var id: String { rawValue }

    /// Nombre del idioma en español (idioma de la interfaz).
    var displayName: String {
        switch self {
        case .spanish:    "Español"
        case .english:    "Inglés"
        case .french:     "Francés"
        case .italian:    "Italiano"
        case .german:     "Alemán"
        case .portuguese: "Portugués"
        }
    }

    /// Nombre del idioma en su propia lengua (útil para la otra persona).
    var nativeName: String {
        switch self {
        case .spanish:    "Español"
        case .english:    "English"
        case .french:     "Français"
        case .italian:    "Italiano"
        case .german:     "Deutsch"
        case .portuguese: "Português"
        }
    }

    /// Bandera representativa (solo decorativa).
    var flag: String {
        switch self {
        case .spanish:    "🇪🇸"
        case .english:    "🇺🇸"
        case .french:     "🇫🇷"
        case .italian:    "🇮🇹"
        case .german:     "🇩🇪"
        case .portuguese: "🇧🇷"
        }
    }

    /// Código de idioma para Translation (`Locale.Language`).
    /// Portugués se fija en variante de Brasil; se confirmará en la Fase 2
    /// contra `LanguageAvailability().supportedLanguages`.
    var translationCode: String {
        switch self {
        case .spanish:    "es"
        case .english:    "en"
        case .french:     "fr"
        case .italian:    "it"
        case .german:     "de"
        case .portuguese: "pt-BR"
        }
    }

    /// Locale regional por defecto para el reconocimiento de voz
    /// (`SFSpeechRecognizer(locale:)`). En la Fase 6 se podrá elegir la
    /// variante (es-MX, en-GB, pt-PT…).
    var speechLocaleIdentifier: String {
        switch self {
        case .spanish:    "es-ES"
        case .english:    "en-US"
        case .french:     "fr-FR"
        case .italian:    "it-IT"
        case .german:     "de-DE"
        case .portuguese: "pt-BR"
        }
    }

    /// Código BCP-47 para `AVSpeechSynthesisVoice(language:)`.
    var voiceLanguageCode: String { speechLocaleIdentifier }

    var translationLanguage: Locale.Language {
        Locale.Language(identifier: translationCode)
    }

    var speechLocale: Locale {
        Locale(identifier: speechLocaleIdentifier)
    }

    // MARK: Textos en el idioma de la otra persona (modo cara a cara)

    /// «Hablar» en este idioma.
    var speakLabel: String {
        switch self {
        case .spanish:    "Hablar"
        case .english:    "Speak"
        case .french:     "Parler"
        case .italian:    "Parla"
        case .german:     "Sprechen"
        case .portuguese: "Falar"
        }
    }

    /// Invitación a hablar, en este idioma.
    var tapToSpeakPrompt: String {
        switch self {
        case .spanish:    "Toca el micrófono y habla en español"
        case .english:    "Tap the microphone and speak in English"
        case .french:     "Touchez le micro et parlez en français"
        case .italian:    "Tocca il microfono e parla in italiano"
        case .german:     "Tippen Sie auf das Mikrofon und sprechen Sie Deutsch"
        case .portuguese: "Toque no microfone e fale em português"
        }
    }

    /// «Escuchando…» en este idioma.
    var listeningLabel: String {
        switch self {
        case .spanish:    "Escuchando…"
        case .english:    "Listening…"
        case .french:     "J'écoute…"
        case .italian:    "Sto ascoltando…"
        case .german:     "Ich höre zu…"
        case .portuguese: "Ouvindo…"
        }
    }

    /// Frase de ejemplo usada por los servicios simulados de la Fase 1.
    /// Es la misma frase en los seis idiomas, para que la traducción
    /// simulada sea coherente.
    var samplePhrase: String {
        switch self {
        case .spanish:    "¿Dónde está la estación de tren más cercana?"
        case .english:    "Where is the nearest train station?"
        case .french:     "Où se trouve la gare la plus proche ?"
        case .italian:    "Dov'è la stazione ferroviaria più vicina?"
        case .german:     "Wo ist der nächste Bahnhof?"
        case .portuguese: "Onde fica a estação de trem mais próxima?"
        }
    }
}
