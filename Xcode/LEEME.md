# Psico Bros. — app nativa para macOS

App de macOS (AppKit + WKWebView) que muestra el juego de `../index.html` en su propia ventana
y lee los controles con el framework **GameController** de Apple.

## Abrir y ejecutar

1. Abre `PsicoBros.xcodeproj` en Xcode.
2. Elige el esquema **PsicoBros** y el destino **My Mac**.
3. Pulsa ▶︎ (Cmd+R).

La app se firma con "Sign to Run Locally", así que no hace falta una cuenta de desarrollador
para probarla en tu Mac. Para compartirla con otras personas, en *Signing & Capabilities*
elige tu equipo (Team).

## Qué hace

- **Controles:** Xbox, PlayStation (DualShock / DualSense), Switch Pro y controles MFi.
  Se detectan al conectarlos, también si ya estaban conectados al abrir la app.
  Con varios controles, se usa el último que se tocó.
- **Botones:** inferior = saltar; izquierdo, derecho, L1 o R1 = correr / lanzar; Menu / Options / + = pausa.
  Cruceta o palanca izquierda para moverte.
- **Vibración** en los controles que la tienen.
- **Sonido** sin necesidad de hacer clic primero.
- **Pantalla completa** con la tecla F, Ctrl+Cmd+F o el botón verde de la ventana.
- **Menú Juego → Reiniciar juego** (Cmd+R).
- Se marca como juego (`public.app-category.games`), así que macOS puede activar el Modo Juego.

## Archivos

| Archivo | Para qué sirve |
|---|---|
| `PsicoBros/main.swift` | Arranca la app. |
| `PsicoBros/AppDelegate.swift` | Ventana, menú y WKWebView que carga el juego. |
| `PsicoBros/GamepadBridge.swift` | Lee los controles y la vibración, y se los pasa al juego. |
| `PsicoBros/ScriptMessageProxy.swift` | Recibe los mensajes del juego (vibración, pantalla completa). |
| `../index.html` | El juego. Xcode lo copia dentro de la app al compilar. |

El juego es un solo archivo compartido: si editas `../index.html`, la próxima compilación ya lo incluye.

## Cómo se comunican

- Swift → juego: `psicoNativePad.connect(nombre, tipo)`, `psicoNativePad.update({left, right, down, jump, run, start})`
  y `psicoNativePad.disconnect()`.
- Juego → Swift: `window.webkit.messageHandlers.psico.postMessage({ rumble: [fuerte, suave, ms] })`
  o `{ fullscreen: true }`.
- Dentro de la app, el juego desactiva los controles del navegador para no leer el mismo botón dos veces.
