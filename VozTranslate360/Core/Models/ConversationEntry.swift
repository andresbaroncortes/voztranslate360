//
//  ConversationEntry.swift
//  VozTranslate 360 — Atlas Business
//
//  Registro persistente del historial (SwiftData).
//  Solo se guarda TEXTO. El audio nunca se almacena.
//

import Foundation
import SwiftData

@Model
final class ConversationEntry {
    var entryID: UUID
    var createdAt: Date
    var speakerRaw: String
    var sourceLanguageRaw: String
    var targetLanguageRaw: String
    var originalText: String
    var translatedText: String
    var processedOnDevice: Bool

    init(
        entryID: UUID = UUID(),
        createdAt: Date = .now,
        speaker: Speaker,
        sourceLanguage: AppLanguage,
        targetLanguage: AppLanguage,
        originalText: String,
        translatedText: String,
        processedOnDevice: Bool
    ) {
        self.entryID = entryID
        self.createdAt = createdAt
        self.speakerRaw = speaker.rawValue
        self.sourceLanguageRaw = sourceLanguage.rawValue
        self.targetLanguageRaw = targetLanguage.rawValue
        self.originalText = originalText
        self.translatedText = translatedText
        self.processedOnDevice = processedOnDevice
    }

    /// Crea un registro a partir de un turno de conversación.
    convenience init(turn: ConversationTurn) {
        self.init(
            entryID: turn.id,
            createdAt: turn.date,
            speaker: turn.speaker,
            sourceLanguage: turn.sourceLanguage,
            targetLanguage: turn.targetLanguage,
            originalText: turn.originalText,
            translatedText: turn.translatedText,
            processedOnDevice: turn.processedOnDevice
        )
    }

    var speaker: Speaker { Speaker(rawValue: speakerRaw) ?? .me }
    var sourceLanguage: AppLanguage? { AppLanguage(rawValue: sourceLanguageRaw) }
    var targetLanguage: AppLanguage? { AppLanguage(rawValue: targetLanguageRaw) }
}
