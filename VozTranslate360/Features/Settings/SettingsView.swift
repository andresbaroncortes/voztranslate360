//
//  SettingsView.swift
//  VozTranslate 360 — Atlas Business
//
//  Ajustes: modo de procesamiento, voz y privacidad.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.openURL) private var openURL

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

                Section {
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
                } header: {
                    Text("Voz")
                } footer: {
                    Text("Para una voz más natural, descarga voces «mejoradas» o «premium» en Ajustes ▸ Accesibilidad ▸ Contenido leído ▸ Voces. La app usa la mejor voz instalada de cada idioma.")
                }

                Section {
                    Button("Abrir Ajustes de iOS", systemImage: "gear") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                } header: {
                    Text("Permisos")
                } footer: {
                    Text("Micrófono y reconocimiento de voz se piden la primera vez que pulsas un micrófono. Si los negaste, actívalos aquí.")
                }

                Section {
                    Toggle("Guardar historial de texto", isOn: $settings.saveHistory)
                    Label("El audio nunca se guarda: solo se usa en memoria para el dictado.", systemImage: "lock.shield")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Privacidad")
                } footer: {
                    Text("El historial se guarda solo en este iPhone (el guardado automático se activa en la Fase 6). La traducción siempre se hace en el iPhone. Si el dictado no está disponible en el dispositivo y el modo lo permite, iOS lo procesa en los servidores de Apple. No se usan servicios de pago.")
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
