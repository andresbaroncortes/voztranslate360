//
//  ConversationView.swift
//  VozTranslate 360 — Atlas Business
//
//  Pantalla principal: idiomas arriba, conversación en el centro y dos
//  micrófonos abajo (uno por persona) para hablar por turnos.
//

import SwiftUI
import UIKit

struct ConversationView: View {
    @Environment(ConversationViewModel.self) private var viewModel
    @Environment(AppSettings.self) private var settings
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    @State private var pickerSide: ConversationViewModel.LanguageSide?
    @State private var draft = ""
    @State private var showsFaceToFace = false
    @State private var largeTurn: ConversationTurn?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                LanguageBar(
                    source: viewModel.sourceLanguage,
                    target: viewModel.targetLanguage,
                    isEnabled: viewModel.canChangeLanguages,
                    onSelectSource: { pickerSide = .source },
                    onSelectTarget: { pickerSide = .target },
                    onSwap: { viewModel.swapLanguages() }
                )

                HStack(spacing: 8) {
                    ProcessingModeMenu(settings: settings)
                    ConnectivityChip(isConnected: dependencies.connectivity.isConnected)
                    Spacer()
                }

                transcriptList

                if viewModel.phase != .idle {
                    LiveStatusCard(phase: viewModel.phase, transcript: viewModel.liveTranscript) {
                        viewModel.stopAll()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                TextComposer(
                    text: $draft,
                    language: viewModel.sourceLanguage,
                    isEnabled: viewModel.canTranslateTypedText
                ) {
                    viewModel.translateTyped(draft)
                    draft = ""
                }

                microphoneControls
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(AppBackground())
            .animation(.snappy, value: viewModel.phase)
            .navigationTitle("VozTranslate 360")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cara a cara", systemImage: "person.2.wave.2") {
                        showsFaceToFace = true
                    }
                    .accessibilityHint("Divide la pantalla para conversar con el iPhone sobre la mesa")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Limpiar conversación", systemImage: "trash") {
                        viewModel.clearConversation()
                    }
                    .disabled(viewModel.turns.isEmpty)
                }
            }
            .fullScreenCover(isPresented: $showsFaceToFace) {
                FaceToFaceView()
            }
            .fullScreenCover(item: $largeTurn) { turn in
                LargeTextView(turn: turn)
            }
            .sheet(item: $pickerSide) { side in
                LanguagePickerSheet(
                    side: side,
                    selected: side == .source ? viewModel.sourceLanguage : viewModel.targetLanguage,
                    counterpart: side == .source ? viewModel.targetLanguage : viewModel.sourceLanguage,
                    checker: dependencies.availability
                ) { language in
                    viewModel.select(language, for: side)
                }
            }
            .task {
                #if DEBUG
                if DemoMode.startsListening && viewModel.phase == .idle {
                    viewModel.toggleListening(for: .me)
                }
                if DemoMode.opensLanguagePicker {
                    pickerSide = .target
                }
                if DemoMode.opensFaceToFace {
                    showsFaceToFace = true
                }
                #endif
            }
            // Privacidad: nunca se sigue grabando con la app en segundo plano.
            // (Solo .background: el aviso de permisos de iOS pone la app en
            // .inactive y no debe cortar la grabación.)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background { viewModel.stopAll() }
            }
            // La pantalla no se apaga mientras se escucha, traduce o lee.
            .onChange(of: viewModel.phase) { _, newPhase in
                UIApplication.shared.isIdleTimerDisabled = newPhase != .idle || showsFaceToFace
            }
            .alert("Aviso", isPresented: errorBinding) {
                if viewModel.errorOffersSettings {
                    Button("Abrir Ajustes") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                }
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: Secciones

    @ViewBuilder
    private var transcriptList: some View {
        if viewModel.turns.isEmpty {
            ContentUnavailableView {
                Label("Empieza a conversar", systemImage: "bubble.left.and.bubble.right")
            } description: {
                Text("Pulsa tu micrófono y habla en \(viewModel.sourceLanguage.displayName). La otra persona responde con el suyo.")
            }
            .frame(maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.turns) { turn in
                            TurnBubble(turn: turn, canReplay: viewModel.phase == .idle) {
                                viewModel.replay(turn)
                            } onShowLarge: {
                                largeTurn = turn
                            }
                            .id(turn.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.turns.count) {
                    guard let last = viewModel.turns.last else { return }
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var microphoneControls: some View {
        HStack(alignment: .top) {
            MicButton(
                title: "Yo hablo",
                language: viewModel.sourceLanguage,
                speaker: .me,
                isActive: viewModel.isListening(.me),
                isEnabled: viewModel.canUseMicrophone(.me)
            ) {
                viewModel.toggleListening(for: .me)
            }
            .frame(maxWidth: .infinity)

            MicButton(
                title: "Responde",
                language: viewModel.targetLanguage,
                speaker: .partner,
                isActive: viewModel.isListening(.partner),
                isEnabled: viewModel.canUseMicrophone(.partner)
            ) {
                viewModel.toggleListening(for: .partner)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: {
                if !$0 {
                    viewModel.errorMessage = nil
                    viewModel.errorOffersSettings = false
                }
            }
        )
    }
}

// MARK: - Tarjeta de estado en vivo

/// Muestra lo que se está oyendo, traduciendo o leyendo, con un botón
/// para detener todo en cualquier momento.
struct LiveStatusCard: View {
    let phase: ConversationViewModel.Phase
    let transcript: String
    let onStop: () -> Void

    private var statusText: String {
        switch phase {
        case .idle:        ""
        case .listening:   "Escuchando…"
        case .translating: "Traduciendo en el iPhone…"
        case .speaking:    "Leyendo la traducción…"
        }
    }

    private var statusIcon: String {
        switch phase {
        case .idle:        "circle"
        case .listening:   "waveform"
        case .translating: "character.bubble"
        case .speaking:    "speaker.wave.2.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(statusText, systemImage: statusIcon)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .symbolEffect(.variableColor.iterative, isActive: phase != .idle)
                Spacer()
                Button("Detener", systemImage: "stop.circle.fill", role: .destructive, action: onStop)
                    .font(.footnote.weight(.semibold))
                    .buttonStyle(.borderless)
            }
            if !transcript.isEmpty {
                Text(transcript)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.opacity)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

#Preview {
    let dependencies = AppDependencies.mock()
    let settings = AppSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    return ConversationView()
        .environment(dependencies)
        .environment(settings)
        .environment(ConversationViewModel(dependencies: dependencies, settings: settings))
}
