import AppKit

// Punto de entrada: arranca la app sin storyboard.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
