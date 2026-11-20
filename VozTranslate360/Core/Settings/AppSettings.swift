//
//  AppSettings.swift
//  VozTranslate 360 — Atlas Business
//
//  Preferencias del usuario guardadas en UserDefaults (solo en el iPhone).
//

import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {

    private enum Keys {
        static let processingMode = "settings.processingMode"
        static let autoSpeak = "settings.autoSpeak"
        static let speechRate = "settings.speechRate"
        static let saveHistory = "settings.saveHistory"
        static let sourceLanguage = "settings.sourceLanguage"
        static let targetLanguage = "settings.targetLanguage"
        static let autoEndOnPause = "settings.autoEndOnPause"
        static let autoTurnTaking = "settings.autoTurnTaking"
        static let preferredVoices = "settings.preferredVoices"
        static let dictationLocales = "settings.dictationLocales"
        static let historyRetentionDays = "settings.historyRetentionDays"
    }

    private let defaults: UserDefaults

    var processingMode: ProcessingMode {
        didSet { defaults.set(processingMode.rawValue, forKey: Keys.processingMode) }
    }

    /// Leer la traducción en voz alta automáticamente.
    var autoSpeak: Bool {
        didSet { defaults.set(autoSpeak, forKey: Keys.autoSpeak) }
    }

    /// Velocidad de lectura, 0…1 (0,5 = normal).
    var speechRate: Double {
        didSet { defaults.set(speechRate, forKey: Keys.speechRate) }
    }

    /// Guardar el TEXTO de las conversaciones en el historial local.
    var saveHistory: Bool {
        didSet { defaults.set(saveHistory, forKey: Keys.saveHistory) }
    }

    /// Terminar la frase sola cuando la persona hace una pausa.
    var autoEndOnPause: Bool {
        didSet { defaults.set(autoEndOnPause, forKey: Keys.autoEndOnPause) }
    }

    /// Tras leer una traducción, escuchar automáticamente a la otra persona.
    var autoTurnTaking: Bool {
        didSet { defaults.set(autoTurnTaking, forKey: Keys.autoTurnTaking) }
    }

    /// Voz elegida por idioma (AppLanguage.rawValue → identificador de voz).
    /// Si un idioma no aparece, se usa la mejor voz instalada.
    var preferredVoices: [String: String] {
        didSet { defaults.set(preferredVoices, forKey: Keys.preferredVoices) }
    }

    func voiceIdentifier(for language: AppLanguage) -> String? {
        preferredVoices[language.rawValue]
    }

    func setVoice(_ identifier: String?, for language: AppLanguage) {
        preferredVoices[language.rawValue] = identifier
    }

    /// Variante regional del dictado por idioma (rawValue → identificador de Locale).
    var dictationLocales: [String: String] {
        didSet { defaults.set(dictationLocales, forKey: Keys.dictationLocales) }
    }

    func speechLocale(for language: AppLanguage) -> Locale {
        dictationLocales[language.rawValue].map(Locale.init(identifier:)) ?? language.speechLocale
    }

    func setDictationLocale(_ identifier: String?, for language: AppLanguage) {
        dictationLocales[language.rawValue] = identifier
    }

    /// Días que se conserva el historial (0 = siempre).
    var historyRetentionDays: Int {
        didSet { defaults.set(historyRetentionDays, forKey: Keys.historyRetentionDays) }
    }

    var sourceLanguage: AppLanguage {
        didSet { defaults.set(sourceLanguage.rawValue, forKey: Keys.sourceLanguage) }
    }

    var targetLanguage: AppLanguage {
        didSet { defaults.set(targetLanguage.rawValue, forKey: Keys.targetLanguage) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.processingMode = defaults.string(forKey: Keys.processingMode)
            .flatMap(ProcessingMode.init(rawValue:)) ?? .automatic
        self.autoSpeak = defaults.object(forKey: Keys.autoSpeak) as? Bool ?? true
        self.speechRate = defaults.object(forKey: Keys.speechRate) as? Double ?? 0.5
        self.saveHistory = defaults.object(forKey: Keys.saveHistory) as? Bool ?? true
        self.autoEndOnPause = defaults.object(forKey: Keys.autoEndOnPause) as? Bool ?? true
        self.autoTurnTaking = defaults.object(forKey: Keys.autoTurnTaking) as? Bool ?? false
        self.preferredVoices = defaults.dictionary(forKey: Keys.preferredVoices) as? [String: String] ?? [:]
        self.dictationLocales = defaults.dictionary(forKey: Keys.dictationLocales) as? [String: String] ?? [:]
        self.historyRetentionDays = defaults.object(forKey: Keys.historyRetentionDays) as? Int ?? 0
        self.sourceLanguage = defaults.string(forKey: Keys.sourceLanguage)
            .flatMap(AppLanguage.init(rawValue:)) ?? .spanish
        self.targetLanguage = defaults.string(forKey: Keys.targetLanguage)
            .flatMap(AppLanguage.init(rawValue:)) ?? .english
    }
}
