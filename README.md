# VozTranslate 360

Traductor de conversaciones por voz para iPhone. Funciona con y sin conexión y solo usa frameworks nativos de Apple, sin costos.
Desarrollado por **Atlas Business**.

- Arquitectura y compatibilidad: [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)
- Compilar sin Mac (GitHub Actions + Sideloadly): [docs/COMPILAR_SIN_MAC.md](docs/COMPILAR_SIN_MAC.md)
- Código: [VozTranslate360/](VozTranslate360/) · Pruebas: [VozTranslate360Tests/](VozTranslate360Tests/) · Proyecto: [project.yml](project.yml)

## Estado

| Fase | Contenido | Estado |
|---|---|---|
| 1 | Arquitectura, carpetas y diseño SwiftUI (servicios simulados) | ✅ Aprobada (2026-11-20) |
| 2 | Selección de idiomas y traducción de texto (Apple Translation real) | ✅ Aprobada (2026-11-20) |
| 3 | Reconocimiento de voz y lectura de traducciones | ✅ Aprobada (2026-11-20) |
| 4 | Traducción bidireccional | En desarrollo (rama `fase-4`) |
| 5 | Recursos offline y conectividad | En desarrollo (rama `fase-5`) |
| 6 | Historial, ajustes y optimización | En desarrollo (rama `fase-6`) |
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

## Fase 2 — Lista de comprobación

**Qué cambia:** la traducción ya es **real** (Apple Translation, en el iPhone). El dictado y la voz siguen simulados hasta la Fase 3: al pulsar el micrófono «se oye» la frase de ejemplo, pero su traducción es real.

**Automática (GitHub Actions):**
- [ ] Compila sin errores ni avisos y pasan las pruebas (Fase 1 + `Fase2TranslationTests`).
- [ ] El registro muestra las líneas `DISPONIBILIDAD …` con la matriz real que informa iOS (en el simulador puede diferir del iPhone).
- [ ] Captura `6-idiomas`: selector con estados (en las capturas los estados son **simulados**).

**En el iPhone (Translation no funciona en el simulador):**
1. Instala el `.ipa` con Sideloadly ([docs/COMPILAR_SIN_MAC.md](docs/COMPILAR_SIN_MAC.md)).
2. Abre «Traducir a»: cada idioma muestra **Sin conexión**, **Requiere descarga** o **No disponible**, según tu iPhone.
3. Con conexión y modo **Automático**, escribe «¿Dónde está el baño?» y pulsa ↑. Si el par no está descargado, iOS muestra su hoja de descarga; acepta. Debe aparecer la traducción real.
4. Activa el **modo avión**, cambia el modo a **Sin conexión** y traduce otra frase con el mismo par: debe funcionar sin internet.
5. Con modo **Sin conexión**, elige un par marcado «Requiere descarga» y traduce: debe aparecer un aviso claro (sin intentar descargar).
6. Prueba los seis idiomas en ambos sentidos con ⇄ y anota cuáles quedan «Sin conexión».

## Fase 3 — Lista de comprobación (rama `fase-3`)

**Qué cambia:** dictado real (Speech + AVAudioEngine) y lectura en voz alta (AVSpeechSynthesizer). El audio solo pasa por memoria y nunca se guarda.

| Modo | Dictado |
|---|---|
| Sin conexión | En el iPhone; si el idioma no lo admite, aviso |
| Automático | En el iPhone si el idioma lo admite; si no, servidores de Apple |
| En línea | Servidores de Apple (gratuito, con límites de uso de Apple) |

**Automática (GitHub Actions):** pruebas `Fase3SpeechTests` y líneas `DICTADO …` / `VOZ …` en el registro.

**En el iPhone:**
1. Pulsa «Yo hablo»: iOS pide permiso de **micrófono** y de **reconocimiento de voz**. Acepta.
2. Di «¿Dónde está la estación de tren?» y pulsa ■. Debe aparecer el texto mientras hablas, luego la traducción, y oírse en inglés por el altavoz.
3. Pulsa «Responde» y habla en inglés: debe traducir al español y leerlo.
4. Pulsa «Detener» a mitad de una frase: debe cortar todo al instante.
5. Activa el **modo avión**, modo **Sin conexión**, y dicta en español: debe funcionar (o avisar si tu iPhone no tiene dictado sin conexión para ese idioma).
6. Niega el permiso (Ajustes ▸ VozTranslate 360) y pulsa un micrófono: debe aparecer el aviso con **Abrir Ajustes**.
7. Mientras grabas, sal de la app: al volver, la grabación debe estar detenida.

## Fase 4 — Lista de comprobación (rama `fase-4`)

**Qué cambia:**
- **Cara a cara** (botón 👥 arriba a la izquierda): pantalla dividida; la mitad superior está girada para la otra persona y todo aparece en su idioma, con su micrófono.
- **Fin de frase por pausa:** ya no hace falta pulsar ■; tras ~1,6 s de silencio la frase termina sola (Ajustes ▸ Conversación).
- **Turnos automáticos** (opcional): tras leer la traducción, la app escucha a la otra persona. Si nadie habla en 10 s, el micrófono se cierra.
- **Mostrar en grande** (⤢ en cada burbuja): traducción a pantalla completa, con botón para girarla 180°.

**En el iPhone:**
1. Con la pausa activada, pulsa «Yo hablo», di una frase y espera sin tocar nada: debe terminar sola y traducir.
2. Activa **Turnos automáticos** y conversa con otra persona sin tocar la pantalla.
3. Abre **Cara a cara**, pon el iPhone sobre la mesa y conversen: cada uno ve el texto en su idioma.
4. Pulsa ⤢ en una burbuja y luego «Girar».

## Fase 5 — Lista de comprobación (rama `fase-5`)

**Qué cambia:**
- Conexión **real** (Network / NWPathMonitor): el chip muestra si hay internet.
- **Ajustes ▸ Idiomas sin conexión:** estado real por idioma de traducción (con botón **Descargar**), dictado en el iPhone y calidad de voz.
- Reglas sin red: en **Automático**, si un idioma no está descargado, aviso inmediato (sin quedarse esperando); en **En línea** sin red se usa el dictado del iPhone si existe.

**En el iPhone:**
1. Ajustes ▸ **Idiomas sin conexión**: anota qué aparece en verde.
2. Con Wi-Fi, pulsa **Descargar** en un idioma: debe aparecer la confirmación de iOS y, al terminar, pasar a «Sin conexión».
3. Activa el **modo avión**: el chip debe cambiar a «Sin conexión» en segundos.
4. En modo avión, traduce con un idioma **no** descargado: aviso claro e inmediato.
5. En modo avión, traduce y dicta con un idioma descargado: debe funcionar.

## Fase 6 — Lista de comprobación (rama `fase-6`)

**Qué cambia:**
- **Historial automático** (solo texto, en el iPhone) si «Guardar historial» está activo; conservar 7/30/90 días o siempre; borrar todo con confirmación.
- **Historial:** búsqueda, agrupado por día (Hoy, Ayer…), tocar para ver en grande, deslizar para borrar o copiar, compartir.
- **Variante regional del dictado** (Ajustes ▸ Conversación): español de España, México, Colombia… según lo que admita iOS, indicando cuáles funcionan sin conexión.
- **Optimización:** la pantalla no se apaga mientras se escucha/traduce o en cara a cara; la conversación en pantalla guarda como máximo 200 frases.

**En el iPhone:**
1. Traduce 3 frases y abre **Historial**: deben aparecer bajo «Hoy». Busca una palabra.
2. Toca una entrada: se abre en grande. Desliza: borrar / copiar.
3. Ajustes ▸ **Variante regional del dictado** ▸ elige **español (Colombia)** (si aparece) y dicta: debe reconocer mejor tu acento.
4. Desactiva «Guardar historial», traduce: no debe aparecer en el historial.
5. «Borrar todo el historial»: pide confirmación y lo vacía.
