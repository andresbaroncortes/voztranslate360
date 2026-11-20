//
//  HistoryView.swift
//  VozTranslate 360 — Atlas Business
//
//  Historial local (SwiftData). En la Fase 1 solo valida que el
//  almacenamiento funciona; el guardado automático llega en la Fase 6.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConversationEntry.createdAt, order: .reverse) private var entries: [ConversationEntry]

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "Sin historial",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Las traducciones guardadas aparecerán aquí. Solo se guarda el texto, nunca el audio.")
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
                            HistoryRow(entry: entry)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Historial")
            .task {
                #if DEBUG
                if DemoMode.isEnabled && entries.isEmpty { insertSampleData() }
                #endif
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    #if DEBUG
                    Button("Datos de ejemplo", systemImage: "wand.and.stars") {
                        insertSampleData()
                    }
                    #endif
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
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
                Text(entry.createdAt, format: .dateTime.day().month().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(entry.originalText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(entry.translatedText)
                .font(.body.weight(.semibold))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: ConversationEntry.self, inMemory: true)
}
