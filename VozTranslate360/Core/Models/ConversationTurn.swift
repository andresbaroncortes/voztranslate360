//
//  ConversationTurn.swift
//  VozTranslate 360 — Atlas Business
//
//  Un turno de la conversación en curso (en memoria).
//  El historial persistente usa `ConversationEntry` (SwiftData).
//

import Foundation

/// Quién habla en la conversación bidireccional.
nonisolated enum Speaker: String, Codable, Sendable {
    /// El usuario del iPhone (habla el idioma de origen).
    case me
    /// La otra persona (habla el idioma de destino).
    case partner

    /// El otro participante de la conversación.
    var other: Speaker { self == .me ? .partner : .me }
}

nonisolated struct ConversationTurn: Identifiable, Equatable, Sendable {
    let id: UUID
    let speaker: Speaker
    let sourceLanguage: AppLanguage
    let targetLanguage: AppLanguage
    let originalText: String
    let translatedText: String
    let processedOnDevice: Bool
    let date: Date

    init(
        id: UUID = UUID(),
        speaker: Speaker,
        sourceLanguage: AppLanguage,
        targetLanguage: AppLanguage,
        originalText: String,
        translatedText: String,
        processedOnDevice: Bool,
        date: Date = .now
    ) {
        self.id = id
        self.speaker = speaker
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.originalText = originalText
        self.translatedText = translatedText
        self.processedOnDevice = processedOnDevice
        self.date = date
    }
}
