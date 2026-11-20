//
//  AppleTranslationService.swift
//  VozTranslate 360 — Atlas Business
//
//  Traducción real con Apple Translation (iOS 18+). Siempre en el iPhone.
//
//  Cómo funciona:
//  En iOS 18, una `TranslationSession` solo se obtiene desde el modificador
//  de vista `.translationTask(_:action:)`. Por eso este servicio:
//   1. Encola cada petición y publica una `TranslationSession.Configuration`
//      para el par de idiomas.
//   2. La vista invisible `TranslationSessionHost` (en RootView) observa esa
//      configuración; SwiftUI ejecuta `.translationTask` y entrega la sesión.
//   3. `serve(_:service:)` atiende la cola de ese par.
//
//  Concurrencia: la sesión NO es Sendable. Por eso se usa solo dentro de
//  `serve`, que es `nonisolated` (fuera del hilo principal); con el servicio
//  (@MainActor) solo se intercambian textos y resultados (Sendable).
//
//  Si el par necesita modelos que no están instalados, iOS muestra su propia
//  hoja de descarga (solo en modo Automático/En línea; en «Sin conexión» se
//  avisa antes, sin intentar descargar).
//

import Foundation
import Observation
import SwiftUI
import Translation

@MainActor
@Observable
final class AppleTranslationService: TranslationProviding {

    private struct LanguagePair: Equatable {
        let source: AppLanguage
        let target: AppLanguage
    }

    private struct PendingRequest {
        let id: UUID
        let text: String
        let pair: LanguagePair
        let continuation: CheckedContinuation<String, Error>
    }

    /// Trabajo que se entrega a la sesión: solo datos Sendable.
    nonisolated struct Job: Sendable {
        let id: UUID
        let text: String
    }

    /// Configuración que observa `TranslationSessionHost`.
    private(set) var configuration: TranslationSession.Configuration?

    @ObservationIgnored private var queue: [PendingRequest] = []
    @ObservationIgnored private var inFlight: [UUID: PendingRequest] = [:]
    @ObservationIgnored private var activePair: LanguagePair?
    @ObservationIgnored private var isSessionRequested = false
    @ObservationIgnored private var isSessionRunning = false

    private let availability: any LanguageAvailabilityChecking

    init(availability: any LanguageAvailabilityChecking) {
        self.availability = availability
    }

    // MARK: TranslationProviding

    func translate(_ text: String,
                   from source: AppLanguage,
                   to target: AppLanguage,
                   mode: ProcessingMode) async throws -> TranslationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationServiceError.emptyText }
        guard source != target else { return TranslationResult(text: trimmed, processedOnDevice: true) }

        // 1. Verificar con iOS antes de intentar nada.
        let status = await availability.availability(from: source, to: target)
        try TranslationPolicy.validate(status, from: source, to: target, mode: mode)

        // 2. Encolar y esperar a que la sesión la atienda.
        let pair = LanguagePair(source: source, target: target)
        let translated = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            queue.append(PendingRequest(id: UUID(), text: trimmed, pair: pair, continuation: continuation))
            requestSessionIfNeeded()
        }
        return TranslationResult(text: translated, processedOnDevice: true)
    }

    // MARK: Cola (hilo principal)

    /// Pide a SwiftUI una sesión para el primer par pendiente.
    private func requestSessionIfNeeded() {
        guard !isSessionRunning, !isSessionRequested, let next = queue.first else { return }
        isSessionRequested = true

        if next.pair == activePair, configuration != nil {
            // Mismo par: invalidar hace que `.translationTask` se ejecute otra vez.
            configuration?.invalidate()
        } else {
            activePair = next.pair
            configuration = TranslationSession.Configuration(
                source: next.pair.source.translationLanguage,
                target: next.pair.target.translationLanguage
            )
        }
    }

    fileprivate func sessionDidStart() {
        isSessionRequested = false
        isSessionRunning = true
    }

    /// Siguiente petición del par activo, o `nil` si no queda ninguna.
    fileprivate func nextJob() -> Job? {
        guard let index = queue.firstIndex(where: { $0.pair == activePair }) else { return nil }
        let request = queue.remove(at: index)
        inFlight[request.id] = request
        return Job(id: request.id, text: request.text)
    }

    fileprivate func complete(_ id: UUID, with result: Result<String, Error>) {
        guard let request = inFlight.removeValue(forKey: id) else { return }
        switch result {
        case .success(let text):
            request.continuation.resume(returning: text)
        case .failure(let error):
            request.continuation.resume(
                throwing: TranslationServiceError.translationFailed(error.localizedDescription)
            )
        }
    }

    fileprivate func sessionDidEnd() {
        isSessionRunning = false
        // Si quedaron peticiones de otro par, se pide otra sesión.
        requestSessionIfNeeded()
    }

    // MARK: Sesión (fuera del hilo principal)

    /// Acción para `.translationTask`. Se crea en un contexto `nonisolated`
    /// para que la sesión no cruce al hilo principal.
    nonisolated static func sessionAction(for service: AppleTranslationService) -> @Sendable (TranslationSession) async -> Void {
        { session in
            await serve(session, service: service)
        }
    }

    nonisolated private static func serve(_ session: TranslationSession, service: AppleTranslationService) async {
        await service.sessionDidStart()
        while !Task.isCancelled, let job = await service.nextJob() {
            do {
                let response = try await session.translate(job.text)
                await service.complete(job.id, with: .success(response.targetText))
            } catch {
                await service.complete(job.id, with: .failure(error))
            }
        }
        await service.sessionDidEnd()
    }
}

// MARK: - Vista puente

/// Vista invisible que mantiene viva la conexión con Translation.
/// Debe estar siempre en la jerarquía (se coloca en `RootView`).
struct TranslationSessionHost: View {
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        if let service = dependencies.translator as? AppleTranslationService {
            SessionView(service: service)
        }
    }

    private struct SessionView: View {
        let service: AppleTranslationService

        var body: some View {
            Color.clear
                .frame(width: 1, height: 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .translationTask(service.configuration,
                                 action: AppleTranslationService.sessionAction(for: service))
        }
    }
}
