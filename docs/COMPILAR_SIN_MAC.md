# Compilar e instalar sin Mac

Atlas Business · VozTranslate 360

## Cómo funciona

```
Windows (VS Code) ──git push──▶ GitHub ──▶ Mac en la nube (GitHub Actions)
                                              │ xcodegen → xcodebuild test → capturas → .ipa
                                              ▼
                              Artifacts: capturas-simulador · ipa-sin-firmar · registros
                                              │
Windows ◀──── descargar .ipa ─────────────────┘
   └─ Sideloadly firma con tu Apple ID ──USB──▶ iPhone
```

## 1. Crear el repositorio en GitHub (una vez)

1. Crea una cuenta en https://github.com si no la tienes.
2. Pulsa **New repository**:
   - Nombre: `voztranslate360`
   - Visibilidad: **Private**
   - Sin README, sin .gitignore y sin licencia (ya existen aquí).
3. Copia la URL del repositorio: `https://github.com/TU_USUARIO/voztranslate360.git`.

**Costo:** en repositorios privados, la cuenta gratuita incluye 2.000 minutos de Actions al mes, y los minutos de macOS cuentan 10 veces. Eso equivale a unos 200 minutos de Mac al mes. Cada ejecución tarda entre 10 y 15 minutos, así que caben unas 15 al mes. Consulta el consumo en **Settings ▸ Billing**. Un repositorio público no tiene ese límite, pero el código quedaría visible para cualquiera.

## 2. Subir el código (desde la terminal de VS Code)

```powershell
git remote add origin https://github.com/TU_USUARIO/voztranslate360.git
git push -u origin main
```
La primera vez se abre el navegador para iniciar sesión en GitHub (Git Credential Manager).

## 3. Ver el resultado

1. En GitHub, abre la pestaña **Actions** y entra en la ejecución más reciente, llamada **iOS**.
2. ✅ en verde significa que compiló y pasaron las pruebas. ❌ en rojo significa que algo falló: abre el paso en rojo y copia el error.
3. Al final de la página, en **Artifacts**, descarga:
   - `capturas-simulador.zip`: las pantallas de la app.
   - `ipa-sin-firmar.zip`: la app para el iPhone.
   - `registros.zip`: los logs completos.

Para volver a compilar sin cambiar nada: **Actions ▸ iOS ▸ Run workflow**.

## 4. Instalar en el iPhone con Sideloadly (Windows)

Sideloadly es una herramienta gratuita de terceros que firma el `.ipa` con tu Apple ID y lo instala por USB.

1. Instala los requisitos que indica https://sideloadly.io (iTunes de Apple, versión web, no la de Microsoft Store) y luego Sideloadly.
2. Conecta el iPhone por USB, desbloquéalo y toca **Confiar**.
3. Abre Sideloadly:
   - IPA: `VozTranslate360-sin-firmar.ipa`, que está dentro de `ipa-sin-firmar.zip`.
   - Apple ID: tu correo. **Recomendado: usa un Apple ID secundario**, porque Sideloadly pide la contraseña.
   - Pulsa **Start**.
4. En el iPhone:
   - Activa **Ajustes ▸ Privacidad y seguridad ▸ Modo de desarrollador** y reinicia.
   - Ve a **Ajustes ▸ General ▸ VPN y gestión de dispositivos**, toca tu Apple ID y pulsa **Confiar**.
5. Abre VozTranslate 360.

**Límites de un Apple ID gratuito:** la app caduca a los 7 días (repite el paso 3 de Sideloadly para renovarla) y puedes tener como máximo 3 apps instaladas así. Con el Apple Developer Program (99 USD al año) la app dura un año y puedes usar TestFlight.

## Alternativas si algún día necesitas Xcode completo

- Alquilar un Mac en la nube por horas, como MacinCloud o Scaleway Apple silicon, y usarlo por escritorio remoto.
- Codemagic: un servicio de compilación para iOS con minutos gratuitos al mes, similar a GitHub Actions.
