# VozTranslate 360 — Plan de pruebas en iPhone

Atlas Business · Versión 1.0.0

Marca cada prueba: ✅ funciona · ❌ falla (anota qué pasó) · — no aplica.

**Equipo:** iPhone ________ · iOS ________ · Versión de la app (Ajustes ▸ Acerca de) ________ · Fecha ________

## A. Instalación y permisos
| # | Prueba | Resultado |
|---|---|---|
| A1 | La app abre sin errores tras instalar con Sideloadly | |
| A2 | Al pulsar «Yo hablo» por primera vez se piden micrófono y reconocimiento de voz | |
| A3 | Si niego un permiso, el aviso ofrece «Abrir Ajustes» y lleva a los ajustes de la app | |

## B. Traducción de texto
| # | Prueba | Resultado |
|---|---|---|
| B1 | Escribir «¿Dónde está el baño?» y pulsar ↑ traduce al inglés | |
| B2 | ⇄ intercambia los idiomas y la siguiente traducción va en sentido inverso | |
| B3 | Elegir en «Traducir a» el mismo idioma del otro lado los intercambia | |
| B4 | El selector muestra el estado real: Sin conexión / Requiere descarga / No disponible | |

## C. Voz
| # | Prueba | Resultado |
|---|---|---|
| C1 | «Yo hablo»: el texto aparece mientras hablo y la traducción se oye por el altavoz | |
| C2 | «Responde»: habla en el otro idioma y se traduce al mío | |
| C3 | Con pausa activada, la frase termina sola tras ~1,6 s de silencio | |
| C4 | «Detener» corta al instante la escucha, la traducción o la voz | |
| C5 | Al salir de la app mientras grabo, la grabación queda detenida | |
| C6 | Variante del dictado «español (Colombia)» reconoce bien mi acento | |
| C7 | Ajustes ▸ Voces: ▶ reproduce cada voz; la elegida se usa al traducir | |

## D. Conversación bidireccional
| # | Prueba | Resultado |
|---|---|---|
| D1 | Cara a cara: la mitad superior está girada y todo aparece en el idioma de la otra persona | |
| D2 | Cara a cara: cada persona usa su micrófono y ve la traducción de lo que dijo la otra | |
| D3 | Turnos automáticos: tras leer la traducción, escucha a la otra persona sin tocar nada | |
| D4 | Si nadie habla en 10 s, el micrófono se cierra | |
| D5 | ⤢ muestra la traducción en grande y «Girar» la voltea | |
| D6 | La pantalla no se apaga durante una conversación cara a cara | |

## E. Sin conexión
| # | Prueba | Resultado |
|---|---|---|
| E1 | Ajustes ▸ Idiomas sin conexión ▸ Descargar abre la confirmación de iOS y el idioma pasa a verde | |
| E2 | En modo avión el chip cambia a «Sin conexión» | |
| E3 | Modo avión + idioma descargado: traduce por texto | |
| E4 | Modo avión + idioma descargado: dicta y traduce por voz | |
| E5 | Modo avión + idioma NO descargado: aviso claro e inmediato | |
| E6 | Modo «Sin conexión» con internet: no descarga nada; avisa si falta un idioma | |

## F. Historial y ajustes
| # | Prueba | Resultado |
|---|---|---|
| F1 | Las traducciones aparecen en Historial bajo «Hoy» | |
| F2 | La búsqueda encuentra una palabra del original o de la traducción | |
| F3 | Tocar una entrada la muestra en grande; deslizar borra / copia | |
| F4 | «Guardar historial» desactivado: lo nuevo no se guarda | |
| F5 | «Borrar todo el historial» pide confirmación y lo vacía | |
| F6 | Los ajustes (idiomas, modo, voz, variante) se conservan al cerrar y abrir la app | |
| F7 | Modo oscuro y letra grande se ven bien | |

## G. Matriz real de idiomas (anotar lo que muestra «Idiomas sin conexión»)
| Idioma | Traducción con español | Dictado sin conexión | Mejor voz |
|---|---|---|---|
| Inglés | | | |
| Francés | | | |
| Italiano | | | |
| Alemán | | | |
| Portugués | | | |
| Español (dictado / voz) | — | | |

## Resultado
- [ ] Todas las pruebas críticas (A, B1, C1–C4, E3–E5) funcionan → **Versión 1.0.0 aprobada**
- Observaciones:
