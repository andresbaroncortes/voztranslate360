//
//  AppleLanguageAvailabilityService.swift
//  VozTranslate 360 — Atlas Business
//
//  Pregunta a iOS (Translation.LanguageAvailability, iOS 18+) el estado
//  real de cada par de idiomas: instalado, descargable o no admitido.
//

import Foundation
import Translation

@MainActor
final class AppleLanguageAvailabilityService: LanguageAvailabilityChecking {

    func availability(from source: AppLanguage, to target: AppLanguage) async -> PairAvailability {
        // Se crea una instancia por consulta: es ligera y evita compartir
        // un objeto no-Sendable entre contextos de concurrencia.
        let checker = LanguageAvailability()
        let status = await checker.status(from: source.translationLanguage, to: target.translationLanguage)
        switch status {
        case .installed:   return .installed
        case .supported:   return .needsDownload
        case .unsupported: return .unsupported
        @unknown default:  return .unsupported
        }
    }
}
