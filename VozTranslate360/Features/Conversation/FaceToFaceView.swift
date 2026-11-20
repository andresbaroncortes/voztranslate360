//
//  FaceToFaceView.swift
//  VozTranslate 360 — Atlas Business
//
//  Modo cara a cara: el iPhone se pone sobre la mesa entre las dos
//  personas. La mitad superior está girada 180° para quien está enfrente
//  y muestra todo en SU idioma; la mitad inferior es la del usuario.
//  Cada mitad muestra lo último que dijo la otra persona, ya traducido.
//

import SwiftUI
import UIKit

struct FaceToFaceView: View {
    @Environment(ConversationViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            FacePanel(reader: .partner, viewModel: viewModel)
                .rotationEffect(.degrees(180))

            controls

            FacePanel(reader: .me, viewModel: viewModel)
        }
        .background(AppBackground())
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        // En modo cara a cara la pantalla permanece encendida.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.stopAll()
                dismiss()
            } label: {
                Label("Cerrar", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
            }
            .accessibilityLabel("Cerrar modo cara a cara")

            Rectangle()
                .fill(.separator)
                .frame(height: 1)

            if viewModel.phase != .idle {
                Button {
                    viewModel.stopAll()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.red, in: Circle())
                }
                .accessibilityLabel("Detener")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .animation(.snappy, value: viewModel.phase)
    }
}

// MARK: - Mitad de cada persona

private struct FacePanel: View {
    /// Quién lee esta mitad (y quién habla con su micrófono).
    let reader: Speaker
    let viewModel: ConversationViewModel

    private var language: AppLanguage {
        reader == .me ? viewModel.sourceLanguage : viewModel.targetLanguage
    }

    /// Último mensaje de la otra persona, traducido al idioma de quien lee.
    private var incoming: ConversationTurn? {
        viewModel.turns.last { $0.speaker == reader.other }
    }

    private var isListening: Bool { viewModel.isListening(reader) }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("\(language.flag) \(language.nativeName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let incoming {
                    Button {
                        viewModel.replay(incoming)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.tint(for: reader.other))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(viewModel.phase != .idle)
                    .accessibilityLabel("Repetir")
                }
            }

            Spacer(minLength: 0)

            Group {
                if isListening {
                    Text(viewModel.liveTranscript.isEmpty ? language.listeningLabel : viewModel.liveTranscript)
                        .foregroundStyle(.secondary)
                } else if let incoming {
                    Text(incoming.translatedText)
                        .foregroundStyle(.primary)
                } else {
                    Text(language.tapToSpeakPrompt)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(.title, design: .rounded, weight: .semibold))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity)
            .contentTransition(.opacity)
            .animation(.snappy, value: viewModel.liveTranscript)

            Spacer(minLength: 0)

            MicButton(
                title: language.speakLabel,
                language: language,
                speaker: reader,
                isActive: isListening,
                isEnabled: viewModel.canUseMicrophone(reader),
                subtitle: language.nativeName
            ) {
                viewModel.toggleListening(for: reader)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let dependencies = AppDependencies.mock()
    let settings = AppSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    return FaceToFaceView()
        .environment(ConversationViewModel(dependencies: dependencies, settings: settings))
}
