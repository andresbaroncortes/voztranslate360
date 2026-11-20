//
//  AudioSessionManager.swift
//  VozTranslate 360 — Atlas Business
//
//  Configuración única de AVAudioSession para dictado y lectura en voz alta.
//  • .playAndRecord: grabar y reproducir con la misma sesión.
//  • .defaultToSpeaker: la traducción suena por el altavoz (no por el auricular),
//    para que la otra persona la oiga.
//  • .allowBluetoothA2DP: salida por audífonos o parlantes Bluetooth.
//

import AVFoundation

nonisolated enum AudioSessionManager {

    static func activateForConversation() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord,
                                mode: .default,
                                options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true)
    }

    /// Libera el audio para que otras apps (música, podcasts) continúen.
    static func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
