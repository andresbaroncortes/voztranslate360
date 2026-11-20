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
    @State private var confirmsDeleteHistory = false
    @Environment(ConversationViewModel.self) private var conversation

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
                    NavigationLink {
                        DictationVariantsView()
                    } label: {
                        Label("Variante regional del dictado", systemImage: "globe.americas")
                    }
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
                    Picker("Conservar historial", selection: $settings.historyRetentionDays) {
                        Text("Siempre").tag(0)
                        Text("7 días").tag(7)
                        Text("30 días").tag(30)
                        Text("90 días").tag(90)
                    }
                    .disabled(!settings.saveHistory)
                    Button("Borrar todo el historial", systemImage: "trash", role: .destructive) {
                        confirmsDeleteHistory = true
                    }
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
            .onChange(of: settings.historyRetentionDays) {
                conversation.applyHistoryRetention()
            }
            .confirmationDialog("¿Borrar todo el historial?", isPresented: $confirmsDeleteHistory,
                                titleVisibility: .visible) {
                Button("Borrar todo", role: .destructive) {
                    try? conversation.deleteAllHistory()
                }
            } message: {
                Text("Se eliminarán todas las traducciones guardadas en este iPhone. No se puede deshacer.")
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
    let dependencies = AppDependencies.mock()
    let settings = AppSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    return SettingsView()
        .environment(dependencies)
        .environment(settings)
        .environment(ConversationViewModel(dependencies: dependencies, settings: settings))
}
