import Cocoa

let app = NSApplication.shared
if !AppDelegate.isDemo {
    do {
        try AppDelegate.support.importPreviousInstallation()
    } catch {
        let alert = NSAlert(error: error)
        alert.messageText = "Couldn’t import your settings into Meter"
        alert.runModal()
        exit(EXIT_FAILURE)
    }
}
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)  // menu bar only: no Dock icon, no app switcher
app.run()
