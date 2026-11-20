//
//  MicButton.swift
//  VozTranslate 360 — Atlas Business
//
//  Botón grande de micrófono, pensado para usarse con una mano en la calle.
//  Al grabar muestra un pulso y el icono cambia a «detener».
//

import SwiftUI

struct MicButton: View {
    let title: String
    let language: AppLanguage
    let speaker: Speaker
    let isActive: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    if isActive {
                        Circle()
                            .fill(Theme.gradient(for: speaker))
                            .frame(width: Theme.micDiameter, height: Theme.micDiameter)
                            .phaseAnimator([false, true]) { content, expanded in
                                content
                                    .scaleEffect(expanded ? 1.45 : 1)
                                    .opacity(expanded ? 0 : 0.6)
                            } animation: { expanded in
                                expanded ? .easeOut(duration: 1.1) : nil
                            }
                    }

                    Circle()
                        .fill(Theme.gradient(for: speaker))
                        .frame(width: Theme.micDiameter, height: Theme.micDiameter)
                        .shadow(color: Theme.tint(for: speaker).opacity(0.35), radius: 12, y: 6)

                    Image(systemName: isActive ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(width: Theme.micDiameter * 1.5, height: Theme.micDiameter * 1.5)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text("\(language.flag) \(language.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .sensoryFeedback(.impact(weight: .medium), trigger: isActive)
        .accessibilityLabel(isActive ? "Detener grabación" : "Hablar en \(language.displayName)")
        .accessibilityHint(title)
    }
}

#Preview {
    HStack(spacing: 24) {
        MicButton(title: "Yo hablo", language: .spanish, speaker: .me, isActive: false, isEnabled: true) {}
        MicButton(title: "Responde", language: .english, speaker: .partner, isActive: true, isEnabled: true) {}
    }
    .padding()
}
