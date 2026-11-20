//
//  OfflineResourcesView.swift
//  VozTranslate 360 — Atlas Business
//
//  Estado REAL de los recursos para usar la app sin conexión, idioma por
//  idioma, respecto al idioma principal del usuario:
//  • Traducción: instalada / requiere descarga (con botón Descargar) / no disponible.
//  • Dictado en el iPhone: sí / requiere conexión.
//  • Voz: mejor calidad instalada.
//  Nada se supone: todo se consulta a iOS cada vez que se abre la pantalla.
//

import SwiftUI

struct OfflineResourcesView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.scenePhase) private var scenePhase

    @State private var rows: [AppLanguage: Row] = [:]
    @State private var downloading: Set<AppLanguage> = []
    @State private var errorMessage: String?

    private struct Row {
        var translation: PairAvailability?
        var onDeviceDictation: Bool
        var bestVoice: VoiceQuality?
    }

    /// Idioma principal: el que habla el usuario.
    private var mainLanguage: AppLanguage { settings.sourceLanguage }
    private var others: [AppLanguage] { AppLanguage.allCases.filter { $0 != mainLanguage } }

    var body: some View {
        List {
            Section {
                connectionRow
            }

            Section {
                ForEach(others) { language in
                    translationRow(for: language)
                }
            } header: {
                Text("Traducción con \(mainLanguage.displayName)")
            } footer: {
                Text("«Descargar» abre la confirmación de iOS. Los modelos se guardan en el iPhone y sirven para traducir sin internet. También se gestionan en Ajustes ▸ Apps ▸ Traducir ▸ Idiomas descargados.")
            }

            Section {
                ForEach(AppLanguage.allCases) { language in
                    dictationRow(for: language)
                }
            } header: {
                Text("Dictado en el iPhone")
            } footer: {
                Text("Si un idioma dice «Requiere conexión», añade su teclado en Ajustes ▸ General ▸ Teclado ▸ Teclados y activa el dictado: iOS suele descargar el dictado sin conexión de los idiomas del teclado.")
            }

            Section {
                ForEach(AppLanguage.allCases) { language in
                    voiceRow(for: language)
                }
                NavigationLink("Elegir voz por idioma") { VoicesView() }
            } header: {
                Text("Voz")
            } footer: {
                Text("Todas las voces funcionan sin conexión. Las «Mejoradas» y «Premium» suenan más naturales.")
            }
        }
        .navigationTitle("Idiomas sin conexión")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: mainLanguage) { await refresh() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { Task { await refresh() } }
        }
        .refreshable { await refresh() }
        .alert("Aviso", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: Filas

    private var connectionRow: some View {
        let connected = dependencies.connectivity.isConnected
        return Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(connected ? "Con conexión" : "Sin conexión")
                    .font(.headline)
                Text(connected
                     ? "Puedes descargar idiomas. Con Wi-Fi la descarga es más rápida."
                     : "Solo funcionan los idiomas marcados como disponibles sin conexión.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: connected ? "wifi" : "wifi.slash")
                .foregroundStyle(connected ? .green : .orange)
        }
    }

    private func translationRow(for language: AppLanguage) -> some View {
        HStack {
            Text("\(mainLanguage.flag) ↔ \(language.flag) \(language.displayName)")
            Spacer()
            if downloading.contains(language) {
                ProgressView().controlSize(.small)
            } else {
                switch rows[language]?.translation {
                case .installed:
                    AvailabilityBadge(title: "Sin conexión", systemImage: "checkmark.circle.fill", tint: .green)
                case .needsDownload:
                    Button {
                        download(language)
                    } label: {
                        Label("Descargar", systemImage: "arrow.down.circle")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!dependencies.connectivity.isConnected)
                case .unsupported:
                    AvailabilityBadge(title: "No disponible", systemImage: "xmark.circle", tint: .red)
                case nil:
                    ProgressView().controlSize(.small)
                }
            }
        }
    }

    private func dictationRow(for language: AppLanguage) -> some View {
        HStack {
            Text("\(language.flag) \(language.displayName)")
            Spacer()
            if let row = rows[language] {
                if row.onDeviceDictation {
                    AvailabilityBadge(title: "Sin conexión", systemImage: "checkmark.circle.fill", tint: .green)
                } else {
                    AvailabilityBadge(title: "Requiere conexión", systemImage: "wifi", tint: .orange)
                }
            } else {
                ProgressView().controlSize(.small)
            }
        }
    }

    private func voiceRow(for language: AppLanguage) -> some View {
        HStack {
            Text("\(language.flag) \(language.displayName)")
            Spacer()
            if let quality = rows[language]?.bestVoice {
                QualityBadge(quality: quality)
            } else if rows[language] != nil {
                AvailabilityBadge(title: "Sin voz", systemImage: "speaker.slash", tint: .red)
            } else {
                ProgressView().controlSize(.small)
            }
        }
    }

    // MARK: Acciones

    private func refresh() async {
        var result: [AppLanguage: Row] = [:]
        for language in AppLanguage.allCases {
            let translation: PairAvailability? = language == mainLanguage
                ? nil
                : await dependencies.availability.availability(from: mainLanguage, to: language)
            result[language] = Row(
                translation: translation,
                onDeviceDictation: dependencies.recognizer.supportsOnDeviceDictation(for: language),
                bestVoice: dependencies.synthesizer.availableVoices(for: language).first?.quality
            )
        }
        rows = result
    }

    private func download(_ language: AppLanguage) {
        downloading.insert(language)
        Task {
            do {
                try await dependencies.translator.prepare(from: mainLanguage, to: language)
            } catch {
                errorMessage = error.localizedDescription
            }
            downloading.remove(language)
            await refresh()
        }
    }
}

#Preview {
    NavigationStack {
        OfflineResourcesView()
    }
    .environment(AppSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard))
    .environment(AppDependencies.mock(availability: [.german: .needsDownload, .italian: .unsupported]))
}
