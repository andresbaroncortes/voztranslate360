//
//  HistoryStores.swift
//  VozTranslate 360 — Atlas Business
//
//  Guardado del historial. Solo TEXTO, solo en el iPhone.
//  • SwiftDataHistoryStore: real (SwiftData, en el contenedor de la app).
//  • InMemoryHistoryStore: para pruebas y Previews.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataHistoryStore: HistoryStoring {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ turn: ConversationTurn) {
        context.insert(ConversationEntry(turn: turn))
        try? context.save()
    }

    func deleteAll() throws {
        try context.delete(model: ConversationEntry.self)
        try context.save()
    }

    func deleteOlderThan(_ date: Date) throws {
        try context.delete(model: ConversationEntry.self, where: #Predicate { $0.createdAt < date })
        try context.save()
    }

    func count() -> Int {
        (try? context.fetchCount(FetchDescriptor<ConversationEntry>())) ?? 0
    }
}

@MainActor
final class InMemoryHistoryStore: HistoryStoring {

    private(set) var turns: [ConversationTurn] = []

    func save(_ turn: ConversationTurn) {
        turns.append(turn)
    }

    func deleteAll() throws {
        turns.removeAll()
    }

    func deleteOlderThan(_ date: Date) throws {
        turns.removeAll { $0.date < date }
    }

    func count() -> Int { turns.count }
}
