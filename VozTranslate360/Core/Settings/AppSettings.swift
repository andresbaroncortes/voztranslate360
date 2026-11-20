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
        self.sourceLanguage = defaults.string(forKey: Keys.sourceLanguage)
            .flatMap(AppLanguage.init(rawValue:)) ?? .spanish
        self.targetLanguage = defaults.string(forKey: Keys.targetLanguage)
            .flatMap(AppLanguage.init(rawValue:)) ?? .english
    }
}
