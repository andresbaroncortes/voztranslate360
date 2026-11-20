//
//  LanguagePickerSheet.swift
//  VozTranslate 360 — Atlas Business
//
//  Lista de idiomas. En la Fase 5 cada fila mostrará si el idioma está
//  instalado para usarse sin conexión (consultado al sistema, no supuesto).
//

import SwiftUI

struct LanguagePickerSheet: View {
    let title: String
    let selected: AppLanguage
    let onSelect: (AppLanguage) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(AppLanguage.allCases) { language in
                Button {
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
                        if language == selected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.meTint)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    LanguagePickerSheet(title: "Yo hablo", selected: .spanish) { _ in }
}
