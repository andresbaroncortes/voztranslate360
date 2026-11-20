//
//  Fase4VoiceTests.swift
//  VozTranslate 360 — Atlas Business
//
//  Elección de la voz más natural y voz elegida por el usuario.
//

import Foundation
import Testing
@testable import VozTranslate360

/// Sintetizador espía: registra la voz con la que se pidió leer.
@MainActor
private final class SpySynthesizer: SpeechSynthesizing {
    private(set) var isSpeaking = false
    private(set) var spokenVoices: [String?] = []
    func availableVoices(for language: AppLanguage) -> [VoiceOption] { [] }
    func speak(_ text: String, language: AppLanguage, rate: Double, voiceIdentifier: String?) async {
        spokenVoices.append(voiceIdentifier)
    }
    func stopSpeaking() {}
}

@MainActor
struct Fase4VoiceTests {

    private let voices = [
        VoiceOption(id: "es-ES.std", name: "Mónica", languageCode: "es-ES", quality: .standard),
        VoiceOption(id: "es-MX.enh", name: "Paulina", languageCode: "es-MX", quality: .enhanced),
        VoiceOption(id: "es-ES.enh", name: "Marisol", languageCode: "es-ES", quality: .enhanced),
        VoiceOption(id: "en-US.std", name: "Samantha", languageCode: "en-US", quality: .standard),
        VoiceOption(id: "en-GB.pre", name: "Serena", languageCode: "en-GB", quality: .premium)
    ]

    @Test func priorizaLaCalidadSobreLaRegion() {
        // Una premium británica gana a una estándar estadounidense.
        #expect(VoiceRanking.best(among: voices, for: .english)?.id == "en-GB.pre")
    }

    @Test func aIgualCalidadPrefiereLaRegionPorDefecto() {
        // Dos mejoradas: gana la de es-ES (región por defecto de la app).
        #expect(VoiceRanking.best(among: voices, for: .spanish)?.id == "es-ES.enh")
    }

    @Test func lasVocesAntiguasVanAlFinal() {
        let list = [
            VoiceOption(id: "com.apple.speech.synthesis.voice.Fred", name: "Fred", languageCode: "en-US", quality: .standard),
            VoiceOption(id: "com.apple.eloquence.en-US.Reed", name: "Reed", languageCode: "en-US", quality: .standard),
            VoiceOption(id: "com.apple.voice.compact.en-US.Samantha", name: "Samantha", languageCode: "en-US", quality: .standard)
        ]
        #expect(VoiceRanking.best(among: list, for: .english)?.name == "Samantha")
        #expect(VoiceRanking.candidates(among: list, for: .english).last?.isLegacy == true)
    }

    @Test func aIgualCalidadGanaLaVozPorDefectoDeIOS() {
        let list = [
            VoiceOption(id: "a", name: "Aaron", languageCode: "en-US", quality: .standard),
            VoiceOption(id: "s", name: "Samantha", languageCode: "en-US", quality: .standard)
        ]
        #expect(VoiceRanking.best(among: list, for: .english, defaultIdentifier: "s")?.name == "Samantha")
        // Pero una voz mejorada sigue ganando a la de por defecto.
        let better = list + [VoiceOption(id: "e", name: "Evan", languageCode: "en-US", quality: .enhanced)]
        #expect(VoiceRanking.best(among: better, for: .english, defaultIdentifier: "s")?.name == "Evan")
    }

    @Test func soloVocesDelIdioma() {
        let spanish = VoiceRanking.candidates(among: voices, for: .spanish)
        #expect(spanish.count == 3)
        #expect(spanish.allSatisfy { $0.languageCode.hasPrefix("es") })
        #expect(spanish.last?.quality == .standard)
        #expect(VoiceRanking.best(among: voices, for: .german) == nil)
    }

    @Test func laVozElegidaSeConserva() {
        let suite = "tests.\(UUID().uuidString)"
        let first = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        #expect(first.voiceIdentifier(for: .spanish) == nil)
        first.setVoice("es-MX.enh", for: .spanish)
        let second = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        #expect(second.voiceIdentifier(for: .spanish) == "es-MX.enh")
        second.setVoice(nil, for: .spanish)
        #expect(second.voiceIdentifier(for: .spanish) == nil)
    }

    @Test func laTraduccionSeLeeConLaVozElegida() async {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "tests.\(UUID().uuidString)")!)
        settings.autoSpeak = true
        settings.setVoice("en-GB.pre", for: .english)
        let spy = SpySynthesizer()
        let mock = AppDependencies.mock()
        let dependencies = AppDependencies(translator: mock.translator, availability: mock.availability,
                                           recognizer: mock.recognizer, synthesizer: spy,
                                           connectivity: mock.connectivity)
        let viewModel = ConversationViewModel(dependencies: dependencies, settings: settings)
        viewModel.translateTyped("Hola")

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(5))
        while clock.now < deadline, spy.spokenVoices.isEmpty {
            try? await Task.sleep(for: .milliseconds(50))
        }
        #expect(spy.spokenVoices == ["en-GB.pre"])
    }

    @Test func vocesRealesInstaladas() {
        let installed = VoiceSelector.installedVoices()
        for language in AppLanguage.allCases {
            let list = VoiceRanking.candidates(among: installed, for: language,
                                               defaultIdentifier: VoiceSelector.systemDefaultIdentifier(for: language))
            let summary = list.prefix(4).map { "\($0.name)[\($0.languageCode)] \($0.quality.label)" }
            print("VOZ \(language.voiceLanguageCode): \(list.count) voces → \(summary.joined(separator: ", "))")
        }
    }
}
