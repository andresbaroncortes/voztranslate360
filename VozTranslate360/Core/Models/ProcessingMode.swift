//
//  ProcessingMode.swift
//  VozTranslate 360 — Atlas Business
//
//  Modo de procesamiento elegido por el usuario.
//
//  Qué significa cada modo con los frameworks de Apple:
//  • La TRADUCCIÓN (Translation framework) siempre se ejecuta en el
//    dispositivo. La red solo se usa para descargar los modelos de idioma.
//  • El DICTADO (Speech framework) puede hacerse en el dispositivo o en
//    servidores de Apple, según `requiresOnDeviceRecognition`.
//  • La VOZ (AVSpeechSynthesizer) siempre es local.
//

import Foundation

nonisolated enum ProcessingMode: String, CaseIterable, Identifiable, Codable, Sendable {
    /// Prioriza lo local; usa la red solo si un recurso local no existe.
    case automatic
    /// Permite el dictado en servidores de Apple y la descarga de modelos.
    case online
    /// Solo recursos instalados. Nunca usa la red.
    case offline

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: "Automático"
        case .online:    "En línea"
        case .offline:   "Sin conexión"
        }
    }

    var systemImage: String {
        switch self {
        case .automatic: "sparkles"
        case .online:    "icloud"
        case .offline:   "airplane"
        }
    }

    var explanation: String {
        switch self {
        case .automatic:
            "Usa el iPhone siempre que el idioma esté instalado. Si falta un recurso y hay conexión, usa la red."
        case .online:
            "Permite el dictado con los servidores de Apple y la descarga de idiomas. La traducción sigue siendo local."
        case .offline:
            "Solo usa idiomas instalados en el iPhone. Si falta alguno, la aplicación te avisará."
        }
    }
}
