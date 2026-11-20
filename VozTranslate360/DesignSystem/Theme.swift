//
//  Theme.swift
//  VozTranslate 360 — Atlas Business
//
//  Colores, degradados y medidas comunes. Usa colores del sistema para
//  respetar el modo claro/oscuro y el contraste aumentado.
//

import SwiftUI

@MainActor
enum Theme {
    /// Color del usuario del iPhone (índigo → cian).
    static let meGradient = LinearGradient(
        colors: [Color(red: 0.35, green: 0.34, blue: 0.95), Color(red: 0.13, green: 0.72, blue: 0.86)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Color de la otra persona (naranja → rosa).
    static let partnerGradient = LinearGradient(
        colors: [Color(red: 0.98, green: 0.55, blue: 0.24), Color(red: 0.93, green: 0.29, blue: 0.53)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let meTint = Color(red: 0.35, green: 0.34, blue: 0.95)
    static let partnerTint = Color(red: 0.93, green: 0.40, blue: 0.40)

    static let cornerRadius: CGFloat = 22
    static let micDiameter: CGFloat = 84

    static func gradient(for speaker: Speaker) -> LinearGradient {
        speaker == .me ? meGradient : partnerGradient
    }

    static func tint(for speaker: Speaker) -> Color {
        speaker == .me ? meTint : partnerTint
    }
}

/// Fondo suave de la pantalla principal.
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.meTint.opacity(0.10), Color(.systemBackground), Theme.partnerTint.opacity(0.08)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
