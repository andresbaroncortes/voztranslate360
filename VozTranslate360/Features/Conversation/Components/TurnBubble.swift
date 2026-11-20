//
//  TurnBubble.swift
//  VozTranslate 360 — Atlas Business
//
//  Burbuja de un turno: texto original pequeño y traducción destacada.
//  Mis turnos van a la derecha; los de la otra persona, a la izquierda.
//

import SwiftUI
import UIKit

struct TurnBubble: View {
    let turn: ConversationTurn
    let canReplay: Bool
    let onReplay: () -> Void

    private var isMine: Bool { turn.speaker == .me }

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 40) }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("\(turn.sourceLanguage.flag) → \(turn.targetLanguage.flag)")
                        .font(.caption)
                    if turn.processedOnDevice {
                        Image(systemName: "iphone")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Procesado en el iPhone")
                    }
                    Spacer(minLength: 0)
                    Button(action: onReplay) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.subheadline)
                            .foregroundStyle(Theme.tint(for: turn.speaker))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canReplay)
                    .accessibilityLabel("Repetir traducción")
                }

                Text(turn.originalText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(turn.translatedText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Theme.tint(for: turn.speaker).opacity(0.35), lineWidth: 1)
            )
            .contextMenu {
                Button("Copiar traducción", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = turn.translatedText
                }
                Button("Copiar original", systemImage: "text.quote") {
                    UIPasteboard.general.string = turn.originalText
                }
            }

            if !isMine { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        TurnBubble(
            turn: ConversationTurn(speaker: .me, sourceLanguage: .spanish, targetLanguage: .english,
                                   originalText: AppLanguage.spanish.samplePhrase,
                                   translatedText: AppLanguage.english.samplePhrase, processedOnDevice: true),
            canReplay: true, onReplay: {}
        )
        TurnBubble(
            turn: ConversationTurn(speaker: .partner, sourceLanguage: .english, targetLanguage: .spanish,
                                   originalText: "It's two blocks away.",
                                   translatedText: "Está a dos cuadras.", processedOnDevice: true),
            canReplay: true, onReplay: {}
        )
    }
    .padding()
}
