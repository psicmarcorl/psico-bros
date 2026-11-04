import Foundation
import GameController
import CoreHaptics
import WebKit

/// Lee los controles con el framework GameController de macOS (Xbox, PlayStation,
/// Switch Pro, MFi…) y se los pasa al juego mediante `window.psicoNativePad`,
/// definido en index.html. También hace vibrar el control cuando el juego lo pide.
@MainActor
final class GamepadBridge {
    private weak var webView: WKWebView?
    private var controller: GCController?
    private var pageReady = false
    private var lastState: [String: Bool] = [:]
    private var timer: Timer?
    private var hapticEngine: CHHapticEngine?

    init(webView: WKWebView) {
        self.webView = webView
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(controllerDidConnect(_:)), name: .GCControllerDidConnect, object: nil)
        nc.addObserver(self, selector: #selector(controllerDidDisconnect(_:)), name: .GCControllerDidDisconnect, object: nil)
        nc.addObserver(self, selector: #selector(controllerDidBecomeCurrent(_:)), name: .GCControllerDidBecomeCurrent, object: nil)

        // Un control que ya estaba conectado al abrir la app.
        if let existing = GCController.current ?? GCController.controllers().first {
            select(existing)
        }

        // Se lee el estado 60 veces por segundo y solo se envía al juego si cambió.
        // El temporizador corre en el hilo principal, igual que esta clase.
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    /// Se llama cuando index.html termina de cargar (también al reiniciar el juego).
    func pageDidLoad() {
        pageReady = true
        lastState = [:]
        if let c = controller { announce(c) }
    }

    // MARK: - Conexión y desconexión

    @objc private func controllerDidConnect(_ note: Notification) {
        guard let c = note.object as? GCController else { return }
        if controller == nil { select(c) }
    }

    /// macOS marca como "actual" el último control que se usó: el juego cambia a ese.
    @objc private func controllerDidBecomeCurrent(_ note: Notification) {
        guard let c = note.object as? GCController, c !== controller else { return }
        select(c)
    }

    @objc private func controllerDidDisconnect(_ note: Notification) {
        guard let c = note.object as? GCController, c === controller else { return }
        controller = nil
        stopHaptics()
        lastState = [:]
        if let next = GCController.controllers().first(where: { $0 !== c }) {
            select(next)
        } else {
            run("window.psicoNativePad && psicoNativePad.disconnect()")
        }
    }

    private func select(_ c: GCController) {
        controller = c
        stopHaptics()
        lastState = [:]
        c.playerIndex = .index1 // enciende la luz de "jugador 1" en los controles que la tienen
        announce(c)
    }

    private func announce(_ c: GCController) {
        let name = c.vendorName ?? "Control"
        run("window.psicoNativePad && psicoNativePad.connect(\(jsString(name)), '\(kind(of: c))')")
    }

    /// Tipo de control, para que el juego muestre los nombres correctos de los botones.
    private func kind(of c: GCController) -> String {
        if let pad = c.extendedGamepad {
            if pad is GCXboxGamepad { return "xbox" }
            if pad is GCDualShockGamepad || pad is GCDualSenseGamepad { return "ps" }
        }
        let text = (c.productCategory + " " + (c.vendorName ?? "")).lowercased()
        if text.contains("xbox") { return "xbox" }
        if text.contains("dualshock") || text.contains("dualsense") || text.contains("playstation") { return "ps" }
        if text.contains("switch") || text.contains("joy-con") || text.contains("nintendo") { return "switch" }
        return "generic"
    }

    // MARK: - Lectura de botones

    private func poll() {
        guard pageReady, let c = controller else { return }
        var s: [String: Bool] = [:]
        if let g = c.extendedGamepad {
            let x = g.leftThumbstick.xAxis.value
            let y = g.leftThumbstick.yAxis.value
            s["left"] = g.dpad.left.isPressed || x < -0.5
            s["right"] = g.dpad.right.isPressed || x > 0.5
            s["down"] = g.dpad.down.isPressed || y < -0.5
            // Botón inferior = saltar; izquierdo, derecho o gatillos superiores = correr / lanzar.
            s["jump"] = g.buttonA.isPressed
            s["run"] = g.buttonX.isPressed || g.buttonB.isPressed || g.leftShoulder.isPressed || g.rightShoulder.isPressed
            s["start"] = g.buttonMenu.isPressed
        } else if let m = c.microGamepad {
            s["left"] = m.dpad.left.isPressed
            s["right"] = m.dpad.right.isPressed
            s["down"] = m.dpad.down.isPressed
            s["jump"] = m.buttonA.isPressed
            s["run"] = m.buttonX.isPressed
            s["start"] = m.buttonMenu.isPressed
        } else {
            return
        }
        if s == lastState { return }
        lastState = s
        let fields = s.map { "\"\($0.key)\":\($0.value)" }.joined(separator: ",")
        run("window.psicoNativePad && psicoNativePad.update({\(fields)})")
    }

    // MARK: - Vibración

    func rumble(strong: Double, weak: Double, milliseconds: Double) {
        guard let haptics = controller?.haptics else { return } // no todos los controles vibran
        do {
            if hapticEngine == nil {
                hapticEngine = haptics.createEngine(withLocality: .default)
                try hapticEngine?.start()
            }
            guard let engine = hapticEngine else { return }
            let intensity = Float(min(1, max(strong, weak)))
            let sharpness = Float(min(1, max(0, weak)))
            let event = CHHapticEvent(eventType: .hapticContinuous,
                                      parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                                   CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)],
                                      relativeTime: 0,
                                      duration: milliseconds / 1000)
            let player = try engine.makePlayer(with: CHHapticPattern(events: [event], parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            stopHaptics() // se vuelve a crear en la siguiente vibración
        }
    }

    private func stopHaptics() {
        hapticEngine?.stop(completionHandler: nil)
        hapticEngine = nil
    }

    // MARK: - Utilidades

    private func run(_ js: String) {
        guard pageReady else { return }
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    /// Convierte un texto en un literal de JavaScript seguro (con comillas y escapes).
    private func jsString(_ s: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: [s]),
              let array = String(data: data, encoding: .utf8) else { return "\"Control\"" }
        return String(array.dropFirst().dropLast())
    }
}
