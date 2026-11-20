//
//  Fase6HistoryTests.swift
//  VozTranslate 360 — Atlas Business
//
//  Pruebas de la Fase 6: guardado del historial, conservación por días,
//  borrado, variante regional del dictado y límite de turnos en memoria.
//

import Foundation
import SwiftData
import Testing
@testable import VozTranslate360

@MainActor
struct Fase6HistoryTests {

    private func makeSettings() -> AppSettings {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "tests.\(UUID().uuidString)")!)
        settings.autoSpeak = false
        return settings
    }

    private func waitUntil(timeout: Duration = .seconds(10), _ condition: () -> Bool) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return condition()
    }

    private func turn(daysAgo: Double) -> ConversationTurn {
        ConversationTurn(speaker: .me, sourceLanguage: .spanish, targetLanguage: .english,
                         originalText: "Hola", translatedText: "Hello", processedOnDevice: true,
                         date: Date.now.addingTimeInterval(-daysAgo * 86_400))
    }

    // MARK: Guardado

    @Test func seGuardaSiElHistorialEstaActivo() async {
        let history = InMemoryHistoryStore()
        let viewModel = ConversationViewModel(dependencies: .mock(history: history), settings: makeSettings())
        viewModel.translateTyped("Hola")
        let saved = await waitUntil { history.count() == 1 }
        #expect(saved)
        #expect(history.turns.first?.originalText == "Hola")
    }

    @Test func noSeGuardaSiElHistorialEstaDesactivado() async {
        let history = InMemoryHistoryStore()
        let settings = makeSettings()
        settings.saveHistory = false
        let viewModel = ConversationViewModel(dependencies: .mock(history: history), settings: settings)
        viewModel.translateTyped("Hola")
        let finished = await waitUntil { viewModel.turns.count == 1 && viewModel.phase == .idle }
        #expect(finished)
        #expect(history.count() == 0)
    }

    @Test func conservacionBorraLoAntiguo() {
        let history = InMemoryHistoryStore()
        history.save(turn(daysAgo: 40))
        history.save(turn(daysAgo: 10))
        history.save(turn(daysAgo: 1))
        let settings = makeSettings()
        settings.historyRetentionDays = 30
        let viewModel = ConversationViewModel(dependencies: .mock(history: history), settings: settings)
        viewModel.applyHistoryRetention()
        #expect(history.count() == 2)
    }

    @Test func conservarSiempreNoBorraNada() {
        let history = InMemoryHistoryStore()
        history.save(turn(daysAgo: 400))
        let viewModel = ConversationViewModel(dependencies: .mock(history: history), settings: makeSettings())
        viewModel.applyHistoryRetention()
        #expect(history.count() == 1)
    }

    @Test func borrarTodoElHistorial() throws {
        let history = InMemoryHistoryStore()
        history.save(turn(daysAgo: 1))
        history.save(turn(daysAgo: 2))
        let viewModel = ConversationViewModel(dependencies: .mock(history: history), settings: makeSettings())
        try viewModel.deleteAllHistory()
        #expect(history.count() == 0)
    }

    // MARK: SwiftData real (en memoria)

    @Test func swiftDataGuardaConservaYBorra() throws {
        let container = try ModelContainer(for: ConversationEntry.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = SwiftDataHistoryStore(context: container.mainContext)
        store.save(turn(daysAgo: 40))
        store.save(turn(daysAgo: 2))
        #expect(store.count() == 2)

        try store.deleteOlderThan(Date.now.addingTimeInterval(-30 * 86_400))
        #expect(store.count() == 1)

        let remaining = try container.mainContext.fetch(FetchDescriptor<ConversationEntry>())
        #expect(remaining.first?.turn.translatedText == "Hello")

        try store.deleteAll()
        #expect(store.count() == 0)
    }

    // MARK: Memoria

    @Test func limiteDeTurnosEnPantalla() async {
        let viewModel = ConversationViewModel(dependencies: .mock(), settings: makeSettings())
        viewModel.maxTurnsInMemory = 2
        for text in ["uno", "dos", "tres"] {
            viewModel.translateTyped(text)
            _ = await waitUntil { viewModel.phase == .idle && viewModel.turns.last?.originalText == text }
        }
        #expect(viewModel.turns.count == 2)
        #expect(viewModel.turns.map(\.originalText) == ["dos", "tres"])
    }

    // MARK: Variante regional del dictado

    @Test func varianteDelDictadoPorDefectoYElegida() {
        let suite = "tests.\(UUID().uuidString)"
        let settings = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        #expect(settings.speechLocale(for: .spanish).identifier == "es-ES")
        settings.setDictationLocale("es-CO", for: .spanish)
        let reloaded = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        #expect(reloaded.speechLocale(for: .spanish).identifier == "es-CO")
        #expect(reloaded.speechLocale(for: .english).identifier == "en-US")
    }

    @Test func variantesRealesDeDictado() {
        let recognizer = AppleSpeechRecognizer(connectivity: MockConnectivityMonitor())
        for language in AppLanguage.allCases {
            let ids = recognizer.dictationLocales(for: language).map(\.identifier)
            print("VARIANTES \(language.translationCode): \(ids.joined(separator: ", "))")
        }
    }
}
