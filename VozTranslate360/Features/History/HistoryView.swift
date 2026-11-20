//
//  HistoryView.swift
//  VozTranslate 360 — Atlas Business
//
//  Historial local (SwiftData): búsqueda, agrupado por día, ver en grande,
//  copiar, compartir y borrar. Solo se guarda el texto, nunca el audio.
//

import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \ConversationEntry.createdAt, order: .reverse) private var entries: [ConversationEntry]

    @State private var searchText = ""
    @State private var largeTurn: ConversationTurn?
    @State private var confirmsDeleteAll = false

    // MARK: Datos

    private var filtered: [ConversationEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return entries }
        return entries.filter {
            $0.originalText.localizedCaseInsensitiveContains(query)
                || $0.translatedText.localizedCaseInsensitiveContains(query)
        }
    }

    /// Entradas agrupadas por día, del más reciente al más antiguo.
    private var sections: [(day: Date, items: [ConversationEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.createdAt) }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }

    // MARK: Vista

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "Sin historial",
                        systemImage: "clock.arrow.circlepath",
                        description: Text(settings.saveHistory
                            ? "Las traducciones aparecerán aquí. Solo se guarda el texto, nunca el audio."
                            : "El guardado del historial está desactivado en Ajustes ▸ Privacidad.")
                    )
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    list
                }
            }
            .navigationTitle("Historial")
            .searchable(text: $searchText, prompt: "Buscar en el historial")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        #if DEBUG
                        Button("Datos de ejemplo", systemImage: "wand.and.stars") {
                            insertSampleData()
                        }
                        #endif
                        Button("Borrar todo el historial", systemImage: "trash", role: .destructive) {
                            confirmsDeleteAll = true
                        }
                        .disabled(entries.isEmpty)
                    } label: {
                        Label("Opciones", systemImage: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog("¿Borrar todo el historial?", isPresented: $confirmsDeleteAll, titleVisibility: .visible) {
                Button("Borrar todo", role: .destructive, action: deleteAll)
            } message: {
                Text("Se eliminarán \(entries.count) traducciones de este iPhone. No se puede deshacer.")
            }
            .fullScreenCover(item: $largeTurn) { turn in
                LargeTextView(turn: turn)
            }
            .task {
                #if DEBUG
                if DemoMode.isEnabled && entries.isEmpty { insertSampleData() }
                #endif
            }
        }
    }

    private var list: some View {
        List {
            ForEach(sections, id: \.day) { section in
                Section {
                    ForEach(section.items) { entry in
                        Button {
                            largeTurn = entry.turn
                        } label: {
                            HistoryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button("Borrar", systemImage: "trash", role: .destructive) {
                                modelContext.delete(entry)
                                try? modelContext.save()
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button("Copiar", systemImage: "doc.on.doc") {
                                UIPasteboard.general.string = entry.translatedText
                            }
                            .tint(Theme.meTint)
                        }
                        .contextMenu {
                            Button("Mostrar en grande", systemImage: "arrow.up.left.and.arrow.down.right") {
                                largeTurn = entry.turn
                            }
                            Button("Copiar traducción", systemImage: "doc.on.doc") {
                                UIPasteboard.general.string = entry.translatedText
                            }
                            ShareLink(item: "\(entry.originalText)\n\(entry.translatedText)") {
                                Label("Compartir", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                } header: {
                    Text(Self.dayTitle(section.day))
                }
            }
        }
    }

    // MARK: Acciones

    private func deleteAll() {
        try? modelContext.delete(model: ConversationEntry.self)
        try? modelContext.save()
    }

    static func dayTitle(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Hoy" }
        if calendar.isDateInYesterday(day) { return "Ayer" }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    #if DEBUG
    /// Solo en compilaciones de depuración: crea registros para probar SwiftData.
    private func insertSampleData() {
        let pairs: [(AppLanguage, AppLanguage)] = [(.spanish, .english), (.english, .spanish), (.spanish, .french)]
        for (index, pair) in pairs.enumerated() {
            let entry = ConversationEntry(
                createdAt: .now.addingTimeInterval(Double(-index) * 600),
                speaker: index.isMultiple(of: 2) ? .me : .partner,
                sourceLanguage: pair.0,
                targetLanguage: pair.1,
                originalText: pair.0.samplePhrase,
                translatedText: pair.1.samplePhrase,
                processedOnDevice: true
            )
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
    #endif
}

struct HistoryRow: View {
    let entry: ConversationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(entry.sourceLanguage?.flag ?? "🏳️") → \(entry.targetLanguage?.flag ?? "🏳️")")
                    .font(.caption)
                Spacer()
                Text(entry.createdAt, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(entry.originalText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(entry.translatedText)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    HistoryView()
        .environment(AppSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard))
        .modelContainer(for: ConversationEntry.self, inMemory: true)
}
