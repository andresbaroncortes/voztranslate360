//
//  DemoMode.swift
//  VozTranslate 360 — Atlas Business
//
//  Modo de demostración, SOLO en compilaciones de depuración (DEBUG).
//  Lo usa la integración continua para generar capturas de pantalla.
//
//  Argumentos de lanzamiento:
//    -mock                            Usa servicios simulados (sin datos de ejemplo).
//    -demo                            Servicios simulados + conversación e historial de ejemplo.
//    -demo-listen                     Empieza a «escuchar» al abrir la app.
//    -demo-picker                     Abre el selector de idioma de destino.
//    -demo-face                       Abre el modo cara a cara.
//    -tab traducir|historial|ajustes  Pestaña inicial.
//
//  En la versión Release todas las propiedades devuelven el valor normal.
//

import Foundation

nonisolated enum DemoMode {

    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    private static func has(_ flag: String) -> Bool {
        #if DEBUG
        return arguments.contains(flag)
        #else
        return false
        #endif
    }

    static var isEnabled: Bool { has("-demo") }
    static var usesMockServices: Bool { has("-demo") || has("-mock") }
    static var startsListening: Bool { has("-demo-listen") }
    static var opensLanguagePicker: Bool { has("-demo-picker") }
    static var opensFaceToFace: Bool { has("-demo-face") }

    static var initialTab: AppTab {
        #if DEBUG
        guard let index = arguments.firstIndex(of: "-tab"),
              arguments.indices.contains(index + 1),
              let tab = AppTab(rawValue: arguments[index + 1]) else {
            return .translate
        }
        return tab
        #else
        return .translate
        #endif
    }
}
