import WebKit

/// WKUserContentController retiene a su manejador; este intermediario usa una
/// referencia débil para no crear un ciclo de memoria con el AppDelegate.
final class ScriptMessageProxy: NSObject, WKScriptMessageHandler {
    private weak var target: WKScriptMessageHandler?

    init(target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
