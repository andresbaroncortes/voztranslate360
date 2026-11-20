//
//  LanguageBar.swift
//  VozTranslate 360 — Atlas Business
//
//  Barra superior con los dos idiomas y el botón de intercambio.
//

import SwiftUI

struct LanguageBar: View {
    let source: AppLanguage
    let target: AppLanguage
    let isEnabled: Bool
    let onSelectSource: () -> Void
    let onSelectTarget: () -> Void
    let onSwap: () -> Void

    @State private var swapRotation: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            LanguagePill(caption: "Yo hablo", language: source, action: onSelectSource)

            Button {
                withAnimation(.spring(duration: 0.4)) { swapRotation += 180 }
                onSwap()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.meGradient, in: Circle())
                    .rotationEffect(.degrees(swapRotation))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Intercambiar idiomas")

            LanguagePill(caption: "Traducir a", language: target, action: onSelectTarget)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius + 4, style: .continuous))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
    }
}

struct LanguagePill: View {
    let caption: String
    let language: AppLanguage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(language.flag)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 0) {
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(language.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(caption): \(language.displayName)")
        .accessibilityHint("Toca para cambiar el idioma")
    }
}

#Preview {
    LanguageBar(source: .spanish, target: .english, isEnabled: true, onSelectSource: {}, onSelectTarget: {}, onSwap: {})
        .padding()
}
