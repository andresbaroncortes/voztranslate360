# VozTranslate 360 — Instalación en iPhone

Atlas Business · Versión 1.0.0

## Requisitos

- iPhone con **iOS 18 o posterior**.
- PC con Windows y **iTunes descargado de la web de Apple** (no el de Microsoft Store).
- **Sideloadly** (https://sideloadly.io).
- Un **Apple ID**. Se recomienda uno secundario, porque Sideloadly pide su contraseña.

## 1. Obtener el instalador (.ipa)

**Opción A: versión publicada (recomendada)**
En GitHub ▸ repositorio ▸ **Releases**, descarga `VozTranslate360-v1.0.0.ipa`.

**Opción B: última compilación**
En GitHub ▸ **Actions** ▸ la ejecución más reciente en verde ▸ **Artifacts** ▸ `ipa-sin-firmar`.

## 2. Instalar con Sideloadly

1. Conecta el iPhone por cable, desbloquéalo y toca **Confiar** si te lo pide.
2. Abre Sideloadly: tu iPhone debe aparecer en **iDevice**. Si aparece «no devices detected», revisa que iTunes sea el de la web de Apple.
3. Arrastra el `.ipa` al ícono **IPA**, escribe tu Apple ID y pulsa **Start**.
4. Espera a que diga **Done**.

## 3. Primera vez en el iPhone

1. **Configuración ▸ General ▸ VPN y gestión de dispositivos ▸** tu Apple ID **▸ Confiar**.
2. **Configuración ▸ Privacidad y seguridad ▸ Modo de desarrollador ▸** activar, reiniciar y confirmar con **Activar**.
3. Abre VozTranslate 360 y acepta los permisos de **micrófono** y de **reconocimiento de voz** la primera vez que pulses un micrófono.

## 4. Preparar el uso sin conexión (antes de viajar)

Hazlo con Wi-Fi y el iPhone cargando:

1. **VozTranslate 360 ▸ Ajustes ▸ Idiomas sin conexión ▸ Descargar** en cada idioma que vayas a usar.
2. **Voces naturales:** Configuración de iOS ▸ Accesibilidad ▸ Contenido leído ▸ Voces ▸ idioma ▸ voz «Mejorada» o «Premium» ▸ descargar.
3. **Dictado sin conexión:** Configuración de iOS ▸ General ▸ Teclado ▸ Teclados ▸ añade el teclado de cada idioma y activa **Dictado**.
4. Comprueba en **Idiomas sin conexión** que todo aparezca en verde.
5. Haz una prueba en **modo avión** con el modo **Sin conexión**.

## 5. Renovar la instalación

| Cuenta | Duración | Renovación |
|---|---|---|
| Apple ID gratuito | **7 días** | Conecta el iPhone, abre Sideloadly y vuelve a instalar el mismo `.ipa` (los datos se conservan) |
| Apple Developer Program (99 USD al año) | 1 año | Igual, o mediante TestFlight |

Con un Apple ID gratuito puedes tener como máximo 3 apps instaladas de esta forma.

## 6. Publicar en la App Store (opcional, futuro)

Requiere un Mac (propio o alquilado en la nube) y el Apple Developer Program:
1. Crear el identificador `com.atlasbusiness.VozTranslate360` en developer.apple.com.
2. En App Store Connect, crear la app, subir capturas (las genera GitHub Actions) y la URL de la política de privacidad ([PRIVACIDAD.md](PRIVACIDAD.md) publicada en la web).
3. En el Mac: `xcodegen generate`, abrir el proyecto, **Product ▸ Archive ▸ Distribute App**.
4. Pasar la revisión de Apple.
