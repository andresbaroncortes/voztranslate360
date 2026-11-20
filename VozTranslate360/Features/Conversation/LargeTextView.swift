//
//  LargeTextView.swift
//  VozTranslate 360 — Atlas Business
//
//  Muestra una traducción a pantalla completa y en letra grande, para
//  enseñársela a otra persona (lugares ruidosos, mostradores, taxis).
//  Se puede girar 180° para quien está enfrente.
//

import SwiftUI

struct LargeTextView: View {
    let turn: ConversationTurn
    @Environment(\.dismiss) private var dismiss
    @State private var isFlipped = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button("Cerrar", systemImage: "xmark") { dismiss() }
                    .labelStyle(.iconOnly)
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
                Spacer()
                Button("Girar", systemImage: "rotate.right") {
                    withAnimation(.spring(duration: 0.5)) { isFlipped.toggle() }
                }
                .labelStyle(.iconOnly)
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .accessibilityLabel("Girar para la otra persona")
            }

            Spacer(minLength: 0)

            VStack(spacing: 16) {
                Text("\(turn.targetLanguage.flag) \(turn.targetLanguage.nativeName)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(turn.translatedText)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.3)
                    .textSelection(.enabled)
            }
            .rotationEffect(.degrees(isFlipped ? 180 : 0))

            Spacer(minLength: 0)

            Text(turn.originalText)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
    }
}

#Preview {
    LargeTextView(turn: ConversationTurn(
        speaker: .me, sourceLanguage: .spanish, targetLanguage: .english,
        originalText: AppLanguage.spanish.samplePhrase,
        translatedText: AppLanguage.english.samplePhrase, processedOnDevice: true
    ))
}
