# VozTranslate 360

Traductor de conversaciones por voz para iPhone. Funciona con y sin conexión y solo usa frameworks nativos de Apple, sin costos.
Desarrollado por **Atlas Business**.

- Arquitectura y compatibilidad: [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)
- Compilar sin Mac (GitHub Actions + Sideloadly): [docs/COMPILAR_SIN_MAC.md](docs/COMPILAR_SIN_MAC.md)
- Código: [VozTranslate360/](VozTranslate360/) · Pruebas: [VozTranslate360Tests/](VozTranslate360Tests/) · Proyecto: [project.yml](project.yml)

## Estado

| Fase | Contenido | Estado |
|---|---|---|
| 1 | Arquitectura, carpetas y diseño SwiftUI (servicios simulados) | **En validación** |
| 2 | Selección de idiomas y traducción de texto | Pendiente |
| 3 | Reconocimiento de voz y lectura de traducciones | Pendiente |
| 4 | Traducción bidireccional | Pendiente |
| 5 | Recursos offline y conectividad | Pendiente |
| 6 | Historial, ajustes y optimización | Pendiente |
| 7 | Compilación e instalación en iPhone | Pendiente |

## Dónde se hace cada tarea

| Tarea | Windows (VS Code) | GitHub Actions (Mac en la nube) | iPhone |
|---|---|---|---|
| Escribir código y documentación | ✅ | | |
| Compilar y detectar errores | | ✅ | |
| Pruebas automáticas (Swift Testing) | | ✅ | |
| Capturas de pantalla (claro y oscuro) | | ✅ | |
| Generar el `.ipa` | | ✅ | |
| Instalar la app (Sideloadly) | ✅ | | ✅ |
| Probar micrófono, Translation y modo offline | | | ✅ |

El proyecto de Xcode no se guarda en el repositorio: se genera a partir de [project.yml](project.yml) con XcodeGen. Así se puede trabajar sin Mac.

## Con un Mac (opcional)

```bash
brew install xcodegen
xcodegen generate
open VozTranslate360.xcodeproj
```
Requiere Xcode 26 o posterior. En Xcode, ve a **Signing & Capabilities**, elige tu Apple ID en **Team** y pulsa ⌘R.

## Fase 1 — Lista de comprobación

La Fase 1 usa servicios **simulados**: no usa el micrófono ni traduce de verdad.

**Automática (GitHub Actions):**
- [ ] La compilación para simulador y para iPhone termina sin errores.
- [ ] Pasan todas las pruebas de `VozTranslate360Tests`: idiomas, intercambio, ambos sentidos, «Detener», un solo micrófono a la vez y ajustes que se conservan.

**Visual (capturas):**
- [ ] `1-inicio`: barra de idiomas, chips de modo y conexión, mensaje «Empieza a conversar» y dos micrófonos.
- [ ] `2-conversacion`: burbujas a la derecha (yo) y a la izquierda (la otra persona).
- [ ] `3-escuchando`: tarjeta «Escuchando…» con texto parcial y botón «Detener».
- [ ] `4-historial` y `5-ajustes` correctos.
- [ ] Las versiones oscuras (`dark-*`) se leen bien.

**En el iPhone (opcional en la Fase 1):** instala el `.ipa` con Sideloadly y repite el recorrido a mano.
