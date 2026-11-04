# Psico Bros.

Juego de plataformas en pixel art al estilo de Super Mario Bros. Un psicólogo enfrenta a enemigos que
representan trastornos del DSM-5: fantasmas de ansiedad, dragoncitos de distimia, murciélagos de
insomnio, plantas de TOC y barras de pánico. Al final del nivel espera un jefe: el Gran Dragón de la
Depresión Mayor.

Es un juego educativo. Antes de jugar se muestra un expediente con los criterios principales de cada
trastorno, y cada enemigo y herramienta presenta un cartel breve la primera vez que aparece.
Los trastornos mentales son tratables: pedir ayuda profesional es un acto de valentía.

Por ahora solo incluye el **nivel 1-1** (de prueba), con jefe final.

## Cómo jugar

- **En el navegador:** abre `index.html` (Safari, Chrome, Firefox…). No necesita internet ni instalar nada.
- **Lanzador para macOS:** `Psico Bros.app` abre `index.html` en tu navegador predeterminado.
  Si macOS lo bloquea, haz clic derecho → **Abrir**.
- **App nativa para macOS:** abre `Xcode/PsicoBros.xcodeproj` en Xcode y pulsa ▶︎.
  Más detalles en [Xcode/LEEME.md](Xcode/LEEME.md).

## Controles

| Acción | Teclado | Control |
|---|---|---|
| Moverse | Flechas o A / D | Cruceta o palanca izquierda |
| Saltar | Espacio, Z o ↑ | Botón inferior (A / X / B) |
| Correr y lanzar burbujas | Shift o X | Botón izquierdo (X / Cuadrado / Y) |
| Pausa | P o Enter | Menu / Options / + |
| Silenciar | M | — |
| Pantalla completa | F | — |

El juego detecta controles de Xbox, PlayStation, Switch Pro y genéricos, y muestra sus botones en pantalla.
En el navegador hay que pulsar un botón del control para que se detecte.

## Herramientas terapéuticas

| Objeto | Equivale a | Efecto |
|---|---|---|
| Libro DSM-5 | Hongo | Creces y puedes romper ladrillos |
| Bombilla del Insight | Flor de fuego | Lanzas burbujas de diálogo |
| Loto de Mindfulness | Estrella | Invencible un rato |
| Neuronas | Monedas | 100 = vida extra |
| Red de Apoyo | Hongo 1UP | Vida extra |

## Estructura

```
index.html          El juego completo (HTML5 canvas, sin dependencias)
Psico Bros.app/     Lanzador que abre el juego en el navegador
Xcode/              Proyecto de la app nativa (AppKit + WKWebView + GameController)
```

Los gráficos, la música y los efectos de sonido son originales y están generados por código.
