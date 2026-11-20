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
    @State private var showsOfflineResources = DemoMode.opensOfflineResources

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

                Section {
                    Button {
                        showsOfflineResources = true
                    } label: {
                        HStack {
                            Label("Idiomas sin conexión", systemImage: "arrow.down.circle")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                } footer: {
                    Text("Comprueba y descarga lo necesario para traducir, dictar y leer sin internet.")
                }

                Section {
                    Toggle("Leer traducciones en voz alta", isOn: $settings.autoSpeak)
                    NavigationLink {
                        VoicesView()
                    } label: {
                        Label("Elegir voz por idioma", systemImage: "person.wave.2")
                    }
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
                    Text("Para una voz más natural, descarga voces «Mejoradas» o «Premium» (gratuitas, sin conexión) en Ajustes ▸ Accesibilidad ▸ Contenido leído ▸ Voces. Sin elegir nada, la app usa la mejor voz instalada de cada idioma.")
                }

                Section {
                    Toggle("Terminar la frase al hacer una pausa", isOn: $settings.autoEndOnPause)
                    Toggle("Turnos automáticos", isOn: $settings.autoTurnTaking)
                } header: {
                    Text("Conversación")
                } footer: {
                    Text("Con la pausa activada no hace falta pulsar ■: la frase termina sola tras un silencio breve. Con turnos automáticos, después de leer la traducción la app escucha a la otra persona. Si nadie habla en 10 segundos, el micrófono se cierra.")
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
            .navigationDestination(isPresented: $showsOfflineResources) {
                OfflineResourcesView()
            }
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
