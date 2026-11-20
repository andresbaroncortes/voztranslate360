//
//  TextComposer.swift
//  VozTranslate 360 — Atlas Business
//
//  Campo para escribir una frase y traducirla sin usar la voz
//  (útil en lugares ruidosos o silenciosos).
//

import SwiftUI

struct TextComposer: View {
    @Binding var text: String
    let language: AppLanguage
    let isEnabled: Bool
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    private var canSend: Bool {
        isEnabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "keyboard")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Escribe en \(language.displayName.lowercased())…", text: $text)
                .focused($isFocused)
                .submitLabel(.send)
                .textInputAutocapitalization(.sentences)
                .onSubmit(send)

            if canSend {
                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.meTint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Traducir texto")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .disabled(!isEnabled)
        .animation(.snappy, value: canSend)
    }

    private func send() {
        guard canSend else { return }
        onSend()
        isFocused = false
    }
}

#Preview {
    @Previewable @State var text = "¿A qué hora sale el tren?"
    TextComposer(text: $text, language: .spanish, isEnabled: true) {}
        .padding()
}
