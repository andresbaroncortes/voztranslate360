//
//  StatusChips.swift
//  VozTranslate 360 — Atlas Business
//
//  Indicadores compactos: modo de procesamiento y estado de la conexión.
//

import SwiftUI

struct StatusChip: View {
    let title: String
    let systemImage: String
    var tint: Color = .secondary

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
    }
}

/// Chip con menú para cambiar el modo sin salir de la conversación.
struct ProcessingModeMenu: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Menu {
            Picker("Modo de procesamiento", selection: $settings.processingMode) {
                ForEach(ProcessingMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            }
        } label: {
            StatusChip(
                title: settings.processingMode.title,
                systemImage: settings.processingMode.systemImage,
                tint: .primary
            )
        }
        .accessibilityLabel("Modo de procesamiento: \(settings.processingMode.title)")
    }
}

struct ConnectivityChip: View {
    let isConnected: Bool

    var body: some View {
        StatusChip(
            title: isConnected ? "Con conexión" : "Sin conexión",
            systemImage: isConnected ? "wifi" : "wifi.slash",
            tint: isConnected ? .green : .orange
        )
    }
}
