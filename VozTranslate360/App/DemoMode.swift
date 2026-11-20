//
//  DemoMode.swift
//  VozTranslate 360 — Atlas Business
//
//  Modo de demostración, SOLO en compilaciones de depuración (DEBUG).
//  Lo usa la integración continua para generar capturas de pantalla.
//
//  Argumentos de lanzamiento:
//    -demo                          Carga una conversación y un historial de ejemplo.
//    -demo-listen                   Empieza a «escuchar» al abrir la app.
//    -tab traducir|historial|ajustes  Pestaña inicial.
//
//  En la versión Release todas las propiedades devuelven el valor normal.
//

import Foundation

nonisolated enum DemoMode {

    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static var isEnabled: Bool {
        #if DEBUG
        return arguments.contains("-demo")
        #else
        return false
        #endif
    }

    static var startsListening: Bool {
        #if DEBUG
        return arguments.contains("-demo-listen")
        #else
        return false
        #endif
    }

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
