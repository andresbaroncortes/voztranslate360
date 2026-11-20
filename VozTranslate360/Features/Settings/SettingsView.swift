//
//  SettingsView.swift
//  VozTranslate 360 — Atlas Business
//
//  Ajustes: modo de procesamiento, voz y privacidad.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section {
                    Picker("Modo", selection: $settings.processingMode) {
                        ForEach(ProcessingMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Modo de procesamiento")
                } footer: {
                    Text(settings.processingMode.explanation)
                }

                Section("Idiomas sin conexión") {
                    LabeledContent("Gestionar idiomas descargados") {
                        Text("Fase 5").foregroundStyle(.secondary)
                    }
                }

                Section("Voz") {
                    Toggle("Leer traducciones en voz alta", isOn: $settings.autoSpeak)
                    VStack(alignment: .leading) {
                        Text("Velocidad de lectura")
                        Slider(value: $settings.speechRate, in: 0.3...0.7) {
                            Text("Velocidad de lectura")
                        } minimumValueLabel: {
                            Image(systemName: "tortoise")
                        } maximumValueLabel: {
                            Image(systemName: "hare")
                        }
                    }
                }

                Section {
                    Toggle("Guardar historial de texto", isOn: $settings.saveHistory)
                    Label("El audio nunca se graba ni se guarda.", systemImage: "lock.shield")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Privacidad")
                } footer: {
                    Text("Todo se guarda solo en este iPhone. La aplicación no usa servicios de pago ni envía tus conversaciones a terceros. El guardado automático de las conversaciones se activa en la Fase 6.")
                }

                Section("Acerca de") {
                    LabeledContent("Versión", value: appVersion)
                    LabeledContent("Desarrollado por", value: "Atlas Business")
                }
            }
            .navigationTitle("Ajustes")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard))
}
