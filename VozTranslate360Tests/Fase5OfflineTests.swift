//
//  Fase5OfflineTests.swift
//  VozTranslate 360 — Atlas Business
//
//  Pruebas de la Fase 5: reglas con y sin conexión, descarga de idiomas
//  y monitor de red real.
//

import Foundation
import Testing
@testable import VozTranslate360

@MainActor
struct Fase5OfflineTests {

    private func makeSettings(mode: ProcessingMode = .automatic) -> AppSettings {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "tests.\(UUID().uuidString)")!)
        settings.autoSpeak = false
        settings.processingMode = mode
        return settings
    }

    private func waitUntil(timeout: Duration = .seconds(10), _ condition: () -> Bool) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return condition()
    }

    // MARK: Traducción sin conexión

    @Test func automaticoSinRedAvisaSiHayQueDescargar() {
        #expect(throws: TranslationServiceError.downloadRequiresConnection(.spanish, .german)) {
            try TranslationPolicy.validate(.needsDownload, from: .spanish, to: .german,
                                           mode: .automatic, isConnected: false)
        }
    }

    @Test func instaladoFuncionaSinRedEnCualquierModo() throws {
        for mode in ProcessingMode.allCases {
            try TranslationPolicy.validate(.installed, from: .spanish, to: .english,
                                           mode: mode, isConnected: false)
        }
    }

    @Test func sinRedLaAppMuestraAvisoClaro() async {
        let dependencies = AppDependencies.mock(availability: [.english: .needsDownload], isConnected: false)
        let viewModel = ConversationViewModel(dependencies: dependencies, settings: makeSettings())
        viewModel.translateTyped("Hola")

        let finished = await waitUntil { viewModel.phase == .idle && viewModel.errorMessage != nil }
        #expect(finished)
        #expect(viewModel.errorMessage == TranslationServiceError.downloadRequiresConnection(.spanish, .english).errorDescription)
        #expect(viewModel.turns.isEmpty)
    }

    // MARK: Dictado sin conexión

    @Test func automaticoSinRedNecesitaDictadoLocal() throws {
        #expect(try SpeechPolicy.requiresOnDevice(mode: .automatic, supportsOnDevice: true,
                                                  language: .spanish, isConnected: false))
        #expect(throws: SpeechServiceError.onDeviceUnavailable(.french)) {
            try SpeechPolicy.requiresOnDevice(mode: .automatic, supportsOnDevice: false,
                                              language: .french, isConnected: false)
        }
    }

    @Test func enLineaSinRedRecurreAlDictadoLocal() throws {
        #expect(try SpeechPolicy.requiresOnDevice(mode: .online, supportsOnDevice: true,
                                                  language: .spanish, isConnected: false))
        #expect(throws: SpeechServiceError.recognizerUnavailable(.italian)) {
            try SpeechPolicy.requiresOnDevice(mode: .online, supportsOnDevice: false,
                                              language: .italian, isConnected: false)
        }
    }

    @Test func conRedSeMantieneElComportamientoAnterior() throws {
        #expect(try !SpeechPolicy.requiresOnDevice(mode: .online, supportsOnDevice: true,
                                                   language: .spanish, isConnected: true))
        #expect(try !SpeechPolicy.requiresOnDevice(mode: .automatic, supportsOnDevice: false,
                                                   language: .spanish, isConnected: true))
    }

    // MARK: Descarga de idiomas

    @Test func descargarDejaElParInstalado() async throws {
        let dependencies = AppDependencies.mock(availability: [.german: .needsDownload])
        #expect(await dependencies.availability.availability(from: .spanish, to: .german) == .needsDownload)
        try await dependencies.translator.prepare(from: .spanish, to: .german)
        #expect(await dependencies.availability.availability(from: .spanish, to: .german) == .installed)
    }

    @Test func descargarSinRedAvisa() async {
        let dependencies = AppDependencies.mock(availability: [.german: .needsDownload], isConnected: false)
        await #expect(throws: TranslationServiceError.downloadRequiresConnection(.spanish, .german)) {
            try await dependencies.translator.prepare(from: .spanish, to: .german)
        }
    }

    @Test func servicioRealNoDescargaSinRed() async {
        let service = AppleTranslationService(
            availability: MockLanguageAvailability(overrides: [.italian: .needsDownload]),
            connectivity: MockConnectivityMonitor(isConnected: false)
        )
        await #expect(throws: TranslationServiceError.downloadRequiresConnection(.spanish, .italian)) {
            try await service.prepare(from: .spanish, to: .italian)
        }
    }

    // MARK: Monitor de red real

    @Test func monitorDeRedReal() async {
        let monitor = NetworkConnectivityMonitor()
        try? await Task.sleep(for: .seconds(1))
        print("CONEXION conectado=\(monitor.isConnected) costosa=\(monitor.isExpensive) datosReducidos=\(monitor.isConstrained)")
    }
}
