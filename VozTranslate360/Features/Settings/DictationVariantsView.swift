//
//  DictationVariantsView.swift
//  VozTranslate 360 — Atlas Business
//
//  Variante regional del dictado por idioma (español de España, México,
//  Colombia…). La lista la entrega iOS: solo aparecen variantes reales.
//

import SwiftUI

struct DictationVariantsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(AppDependencies.self) private var dependencies

    private let names = Locale(identifier: "es")

    var body: some View {
        List {
            ForEach(AppLanguage.allCases) { language in
                Section {
                    ForEach(dependencies.recognizer.dictationLocales(for: language), id: \.identifier) { locale in
                        row(locale, language: language)
                    }
                } header: {
                    Text("\(language.flag) \(language.displayName)")
                }
            }
        }
        .navigationTitle("Variante del dictado")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ locale: Locale, language: AppLanguage) -> some View {
        let isSelected = settings.speechLocale(for: language).identifier == locale.identifier
        let onDevice = dependencies.recognizer.supportsOnDeviceDictation(for: locale)
        return Button {
            settings.setDictationLocale(locale.identifier, for: language)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(names.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                        .foregroundStyle(.primary)
                    Text(onDevice ? "Funciona sin conexión" : "Requiere conexión")
                        .font(.caption)
                        .foregroundStyle(onDevice ? .green : .secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").foregroundStyle(Theme.meTint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { DictationVariantsView() }
        .environment(AppSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard))
        .environment(AppDependencies.mock())
}
