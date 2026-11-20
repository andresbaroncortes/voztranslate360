//
//  VoicesView.swift
//  VozTranslate 360 — Atlas Business
//
//  Elección de voz por idioma, con su calidad y botón para probarla.
//  Explica cómo descargar voces «Mejoradas» y «Premium» (gratuitas y
//  sin conexión), que suenan mucho más naturales que las estándar.
//

import SwiftUI

struct VoicesView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.scenePhase) private var scenePhase

    @State private var voices: [AppLanguage: [VoiceOption]] = [:]
    @State private var playingID: String?
    @State private var previewTask: Task<Void, Never>?

    var body: some View {
        List {
            Section {
                Label {
                    Text("Para una voz natural descarga voces **Mejoradas** o **Premium**: Ajustes de iOS ▸ Accesibilidad ▸ Contenido leído ▸ Voces ▸ elige el idioma ▸ toca una voz con esa etiqueta para descargarla. Son gratuitas y funcionan sin conexión. Luego vuelve aquí.")
                        .font(.callout)
                } icon: {
                    Image(systemName: "waveform.badge.plus")
                        .foregroundStyle(Theme.meTint)
                }
            }

            ForEach(AppLanguage.allCases) { language in
                Section {
                    automaticRow(for: language)
                    ForEach(voices[language] ?? []) { voice in
                        voiceRow(voice, language: language)
                    }
                    if (voices[language] ?? []).isEmpty {
                        Text("No hay voces instaladas para este idioma.")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("\(language.flag) \(language.displayName)")
                }
            }
        }
        .navigationTitle("Voces")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadVoices)
        // Al volver de Ajustes de iOS (tras descargar voces) se recarga la lista.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { loadVoices() }
        }
        .onDisappear {
            previewTask?.cancel()
            dependencies.synthesizer.stopSpeaking()
        }
    }

    // MARK: Filas

    private func automaticRow(for language: AppLanguage) -> some View {
        let isSelected = settings.voiceIdentifier(for: language) == nil
        let best = voices[language]?.first
        return Button {
            settings.setVoice(nil, for: language)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Automática")
                        .foregroundStyle(.primary)
                    Text(best.map { "La mejor instalada: \($0.name) · \($0.quality.label)" } ?? "La mejor instalada")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    private func voiceRow(_ voice: VoiceOption, language: AppLanguage) -> some View {
        let isSelected = settings.voiceIdentifier(for: language) == voice.id
        return HStack(spacing: 12) {
            Button {
                settings.setVoice(voice.id, for: language)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(voice.name)
                            .foregroundStyle(.primary)
                        Text(voice.regionName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    QualityBadge(quality: voice.quality)
                    if isSelected {
                        Image(systemName: "checkmark").foregroundStyle(Theme.meTint)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                preview(voice, language: language)
            } label: {
                Image(systemName: playingID == voice.id ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.meTint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playingID == voice.id ? "Detener" : "Probar \(voice.name)")
        }
    }

    // MARK: Acciones

    private func loadVoices() {
        var result: [AppLanguage: [VoiceOption]] = [:]
        for language in AppLanguage.allCases {
            result[language] = dependencies.synthesizer.availableVoices(for: language)
        }
        voices = result
    }

    private func preview(_ voice: VoiceOption, language: AppLanguage) {
        previewTask?.cancel()
        dependencies.synthesizer.stopSpeaking()
        if playingID == voice.id {
            playingID = nil
            return
        }
        playingID = voice.id
        previewTask = Task {
            await dependencies.synthesizer.speak(language.samplePhrase, language: language,
                                                 rate: settings.speechRate, voiceIdentifier: voice.id)
            if playingID == voice.id { playingID = nil }
        }
    }
}

struct QualityBadge: View {
    let quality: VoiceQuality

    private var tint: Color {
        switch quality {
        case .premium:  .purple
        case .enhanced: .blue
        case .standard: .gray
        }
    }

    var body: some View {
        Text(quality.label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

#Preview {
    NavigationStack {
        VoicesView()
    }
    .environment(AppSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard))
    .environment(AppDependencies.mock())
}
