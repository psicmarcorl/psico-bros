import AppKit
import WebKit

/// Crea la ventana del juego, carga index.html en un WKWebView
/// y conecta los controles nativos con el juego.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private var window: NSWindow!
    private var webView: WKWebView!
    private var gamepads: GamepadBridge!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = buildMainMenu()

        let config = WKWebViewConfiguration()
        // Permite que el sonido (Web Audio) arranque sin hacer clic primero.
        config.mediaTypesRequiringUserActionForPlayback = []
        let content = config.userContentController
        // El juego envía mensajes por window.webkit.messageHandlers.psico (vibración, pantalla completa).
        content.add(ScriptMessageProxy(target: self), name: "psico")
        // Avisa al juego de que corre en la app nativa y apaga los controles del navegador,
        // para que solo haya una fuente de entrada (GameController).
        let bootstrap = """
        window.__PSICO_NATIVE__ = true;
        try { Object.defineProperty(navigator, 'getGamepads', { value: () => [] }); } catch (e) {}
        """
        content.addUserScript(WKUserScript(source: bootstrap, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.allowsMagnification = false
        webView.allowsBackForwardNavigationGestures = false
        #if DEBUG
        if #available(macOS 13.3, *) { webView.isInspectable = true } // Safari > Desarrollo para depurar
        #endif

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 768, height: 720),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Psico Bros."
        window.isReleasedWhenClosed = false
        window.backgroundColor = .black
        window.contentMinSize = NSSize(width: 512, height: 480)
        window.collectionBehavior = [.fullScreenPrimary]
        window.contentView = webView
        window.center()
        window.setFrameAutosaveName("PsicoBrosMainWindow")
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(webView)

        gamepads = GamepadBridge(webView: webView)

        guard let url = Bundle.main.url(forResource: "index", withExtension: "html") else {
            fatalError("No se encontró index.html dentro de la app.")
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // MARK: - Navegación

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        gamepads.pageDidLoad()
        window.makeFirstResponder(webView)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // El juego es local: no se navega a ninguna página externa.
        decisionHandler(navigationAction.request.url?.isFileURL == true ? .allow : .cancel)
    }

    // MARK: - Mensajes desde el juego

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        if let r = body["rumble"] as? [Double], r.count == 3 {
            gamepads.rumble(strong: r[0], weak: r[1], milliseconds: r[2])
        }
        if body["fullscreen"] != nil {
            window.toggleFullScreen(nil)
        }
    }

    // MARK: - Menú

    @objc private func reloadGame() { webView.reload() }

    private func buildMainMenu() -> NSMenu {
        let main = NSMenu()

        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Acerca de Psico Bros.",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Ocultar Psico Bros.", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Ocultar otros",
                                         action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Salir de Psico Bros.", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let gameItem = NSMenuItem()
        main.addItem(gameItem)
        let gameMenu = NSMenu(title: "Juego")
        let reload = gameMenu.addItem(withTitle: "Reiniciar juego", action: #selector(reloadGame), keyEquivalent: "r")
        reload.target = self
        gameItem.submenu = gameMenu

        let windowItem = NSMenuItem()
        main.addItem(windowItem)
        let windowMenu = NSMenu(title: "Ventana")
        let fullScreen = windowMenu.addItem(withTitle: "Pantalla completa",
                                            action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fullScreen.keyEquivalentModifierMask = [.command, .control]
        windowMenu.addItem(withTitle: "Minimizar", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowItem.submenu = windowMenu
        NSApp.windowsMenu = windowMenu

        return main
    }
}
