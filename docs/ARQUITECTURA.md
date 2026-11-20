# VozTranslate 360 — Arquitectura (Fase 1)

Atlas Business · Documento técnico

## 1. Principios

1. **Lo local primero.** La traducción, la voz y el historial siempre se ejecutan en el iPhone. Solo el dictado puede usar servidores de Apple, y solo cuando el modo lo permite.
2. **Cero costos.** Solo frameworks nativos de Apple. No hay APIs comerciales, claves ni suscripciones.
3. **Privacidad.** El audio nunca se guarda. El historial guarda solo texto, en el iPhone (SwiftData), y el usuario puede desactivarlo.
4. **Disponibilidad verificada.** La app no da por hecho que un idioma funcione sin conexión. Lo pregunta al sistema en tiempo de ejecución.
5. **Servicios intercambiables.** Las vistas dependen de protocolos. La Fase 1 usa servicios simulados y cada fase siguiente cambia uno por el real.

## 2. Capas

```
┌──────────────────────────── SwiftUI (Features + DesignSystem) ───────────────────────────┐
│  RootView (TabView) → ConversationView · HistoryView · SettingsView                       │
└───────────────┬───────────────────────────────────────────────────────────────────────────┘
                │ @Environment
┌───────────────▼──────────────┐   ┌──────────────────┐   ┌──────────────────────────────┐
│ ConversationViewModel        │   │ AppSettings      │   │ SwiftData (ConversationEntry) │
│ escuchar → traducir → hablar │   │ UserDefaults     │   │ @Query en HistoryView         │
└───────────────┬──────────────┘   └──────────────────┘   └──────────────────────────────┘
                │ protocolos (Core/Services)
┌───────────────▼───────────────────────────────────────────────────────────────────────────┐
│ AppDependencies (único punto donde se elige la implementación)                            │
│  TranslationProviding        → Mock (F1) → Translation framework            (F2)          │
│  SpeechRecognitionProviding  → Mock (F1) → Speech + AVAudioEngine           (F3)          │
│  SpeechSynthesizing          → Mock (F1) → AVSpeechSynthesizer              (F3)          │
│  ConnectivityMonitoring      → Mock (F1) → Network / NWPathMonitor          (F5)          │
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

Patrón: **MVVM con Observation** (`@Observable`, iOS 17+) e inyección por `@Environment`. Toda la capa de interfaz y los servicios están aislados en `@MainActor`. El trabajo pesado (inferencia, audio) lo hacen los frameworks de Apple en sus propios hilos.

## 3. Flujo de una frase

```
[Pulsar micrófono] → phase = .listening(hablante)
   SpeechRecognitionProviding.startRecognition → resultados parciales → liveTranscript
[Pulsar otra vez]  → stopRecognition → resultado final
   phase = .translating → TranslationProviding.translate
   → se agrega ConversationTurn
   phase = .speaking → SpeechSynthesizing.speak (si «Leer en voz alta» está activo)
   phase = .idle
[Detener] en cualquier momento → stopAll() cancela la tarea, el micrófono y la voz
```

**Bidireccional:** «Yo hablo» traduce origen → destino. «Responde» traduce destino → origen. Son dos botones, así no hay que intercambiar idiomas en cada turno.

## 4. Modos de procesamiento (lo que permite Apple)

| Componente | Automático | En línea | Sin conexión |
|---|---|---|---|
| Dictado (`SFSpeechRecognizer`) | En el iPhone si `supportsOnDeviceRecognition`; si no, en el servidor si hay red | `requiresOnDeviceRecognition = false` | `requiresOnDeviceRecognition = true`; si el idioma no lo soporta, se avisa |
| Traducción (Translation) | Local; descarga el modelo si falta y hay red | Local; permite descargar modelos | Local; solo modelos instalados (`LanguageAvailability.status == .installed`) |
| Voz (`AVSpeechSynthesizer`) | Local | Local | Local |

> **Aclaración importante:** Apple no ofrece traducción «en la nube» en el framework Translation. La traducción **siempre** se hace en el dispositivo. Por eso, «En línea» solo cambia el dictado y las descargas.

## 5. Compatibilidad verificada y lo que falta verificar

| Elemento | Requisito | Estado |
|---|---|---|
| SwiftUI + Observation (`@Observable`) | iOS 17+ | Usado en la Fase 1 |
| SwiftData | iOS 17+ | Usado en la Fase 1 |
| `Tab` de `TabView` | iOS 18+ | Usado en la Fase 1 |
| Translation: `TranslationSession` con `.translationTask`, `LanguageAvailability`, `prepareTranslation()` | iOS 18+ | Fase 2 |
| Translation: `TranslationSession(installedSource:target:)` sin vista | iOS 26+ | Opcional, solo con idiomas instalados |
| Speech: `SFSpeechRecognizer`, `supportsOnDeviceRecognition`, `requiresOnDeviceRecognition` | iOS 13+ | Fase 3 (base) |
| Speech: `SpeechAnalyzer` / `SpeechTranscriber` | iOS 26+ | Se evaluará en la Fase 3 como mejora |
| Network: `NWPathMonitor` | iOS 12+ | Fase 5 |

**Versión mínima elegida: iOS 18.0.** Es la primera versión con una API programática de Translation (necesaria para traducir lo dictado sin la hoja del sistema).

**Idiomas.** Los seis idiomas (es, en, fr, it, de, pt) están entre los idiomas que Apple anuncia para Translation y Speech. Aun así, **qué pares y qué idiomas funcionan sin conexión se confirmará en un iPhone real** con:
- `LanguageAvailability().status(from:to:)` → `.installed` / `.supported` / `.unsupported` (Fase 2)
- `SFSpeechRecognizer(locale:)?.supportsOnDeviceRecognition` (Fase 3)
- `AVSpeechSynthesisVoice(language:)` distinto de `nil` (Fase 3)

La Fase 5 mostrará esta matriz dentro de la app, calculada en el dispositivo.

**Limitaciones conocidas:**
- Translation no es fiable en el simulador. La traducción real se probará en el iPhone.
- El dictado en servidor de Apple es gratuito, pero Apple limita su uso y la duración de cada petición.
- `TranslationSession` (iOS 18) solo se obtiene desde el modificador `.translationTask` de una vista. En la Fase 2 se usará una vista «puente» invisible que atiende las peticiones mientras la sesión está activa.

## 6. Estructura de carpetas

```
VozTranslate360/
├── App/
│   ├── VozTranslate360App.swift      Punto de entrada, entorno y SwiftData
│   └── AppDependencies.swift         Elección de implementaciones
├── Core/
│   ├── Models/
│   │   ├── AppLanguage.swift         Idiomas y códigos por framework
│   │   ├── ProcessingMode.swift      Automático / En línea / Sin conexión
│   │   ├── ConversationTurn.swift    Turno en memoria + Speaker
│   │   └── ConversationEntry.swift   @Model del historial (solo texto)
│   ├── Services/
│   │   └── ServiceProtocols.swift    Contratos de los servicios
│   └── Settings/
│       └── AppSettings.swift         Preferencias (UserDefaults)
├── Services/
│   └── Mock/MockServices.swift       Servicios simulados de la Fase 1
├── Features/
│   ├── Root/RootView.swift
│   ├── Conversation/
│   │   ├── ConversationView.swift
│   │   ├── ConversationViewModel.swift
│   │   └── Components/ (TurnBubble, LanguagePickerSheet)
│   ├── History/HistoryView.swift
│   └── Settings/SettingsView.swift
├── DesignSystem/ (Theme, MicButton, LanguageBar, StatusChips)
└── Resources/PrivacyInfo.xcprivacy   Manifiesto de privacidad (sin rastreo; UserDefaults CA92.1)
```

En las fases siguientes se agregarán `Services/Translation`, `Services/Speech`, `Services/Connectivity` y `Services/Offline`.

## 7. Dependencias

Ninguna dependencia externa. Solo frameworks del sistema: SwiftUI, Observation, SwiftData, Foundation y UIKit (para el portapapeles). Desde las fases 2 a 5: Translation, Speech, AVFoundation y Network.

## 8. Permisos (Info.plist)

Se configuran en la Fase 1, aunque se usarán en la Fase 3:
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`

No se piden permisos de ubicación, contactos ni red local.
