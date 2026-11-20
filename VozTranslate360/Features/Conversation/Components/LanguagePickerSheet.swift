//
//  LanguagePickerSheet.swift
//  VozTranslate 360 — Atlas Business
//
//  Lista de idiomas con el estado REAL de cada par, consultado a iOS:
//  instalado (funciona sin conexión), requiere descarga o no disponible.
//

import SwiftUI

struct LanguagePickerSheet: View {
    let side: ConversationViewModel.LanguageSide
    let selected: AppLanguage
    /// Idioma del otro lado; con él se forma el par que se consulta.
    let counterpart: AppLanguage
    let checker: any LanguageAvailabilityChecking
    let onSelect: (AppLanguage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var statuses: [AppLanguage: PairAvailability] = [:]

    private var title: String { side == .source ? "Yo hablo" : "Traducir a" }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AppLanguage.allCases) { language in
                        row(for: language)
                    }
                } footer: {
                    Text("El estado lo informa iOS para el par con \(counterpart.displayName). «Requiere descarga»: iOS descargará los modelos la primera vez (necesita conexión); después funciona sin internet.")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task(id: counterpart) { await loadStatuses() }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: Fila

    private func row(for language: AppLanguage) -> some View {
        let status = statuses[language]
        let isUnsupported = status == .unsupported && language != counterpart

        return Button {
            onSelect(language)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Text(language.flag).font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(language.nativeName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                trailing(for: language, status: status)
                if language == selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.meTint)
                        .accessibilityLabel("Seleccionado")
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(isUnsupported)
        .opacity(isUnsupported ? 0.45 : 1)
    }

    @ViewBuilder
    private func trailing(for language: AppLanguage, status: PairAvailability?) -> some View {
        if language == counterpart {
            AvailabilityBadge(title: "Intercambiar", systemImage: "arrow.left.arrow.right", tint: .secondary)
        } else if let status {
            switch status {
            case .installed:
                AvailabilityBadge(title: "Sin conexión", systemImage: "checkmark.circle.fill", tint: .green)
            case .needsDownload:
                AvailabilityBadge(title: "Requiere descarga", systemImage: "arrow.down.circle", tint: .orange)
            case .unsupported:
                AvailabilityBadge(title: "No disponible", systemImage: "xmark.circle", tint: .red)
            }
        } else {
            ProgressView().controlSize(.small)
        }
    }

    // MARK: Consulta a iOS

    private func loadStatuses() async {
        for language in AppLanguage.allCases where language != counterpart {
            let pair = side == .source ? (language, counterpart) : (counterpart, language)
            let status = await checker.availability(from: pair.0, to: pair.1)
            statuses[language] = status
        }
    }
}

/// Etiqueta compacta de disponibilidad.
struct AvailabilityBadge: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

#Preview {
    LanguagePickerSheet(
        side: .target,
        selected: .english,
        counterpart: .spanish,
        checker: MockLanguageAvailability(overrides: [.german: .needsDownload, .portuguese: .unsupported])
    ) { _ in }
}
