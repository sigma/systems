import AppKit
import GameController

class StatusBar {
    private var statusItem: NSStatusItem!
    private var enabledItem: NSMenuItem!
    private var naturalScrollItem: NSMenuItem!
    private var controllerItem: NSMenuItem!
    private var statusTimer: DispatchSourceTimer?

    private(set) var isEnabled = true
    var naturalScroll: Bool

    weak var gamepadManager: GamepadManager?

    init(naturalScroll: Bool) {
        self.naturalScroll = naturalScroll
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "gamecontroller.fill",
                accessibilityDescription: "gpad2mouse"
            )
        }

        let menu = NSMenu()

        controllerItem = NSMenuItem(title: "No controller", action: nil, keyEquivalent: "")
        controllerItem.isEnabled = false
        menu.addItem(controllerItem)

        menu.addItem(NSMenuItem.separator())

        enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledItem.target = self
        enabledItem.state = .on
        menu.addItem(enabledItem)

        naturalScrollItem = NSMenuItem(title: "Natural Scrolling", action: #selector(toggleNaturalScroll), keyEquivalent: "")
        naturalScrollItem.target = self
        naturalScrollItem.state = naturalScroll ? .on : .off
        menu.addItem(naturalScrollItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu

        statusTimer = DispatchSource.makeTimerSource(queue: .main) as? DispatchSourceTimer
        statusTimer?.schedule(deadline: .now(), repeating: 2.0)
        statusTimer?.setEventHandler { [weak self] in
            self?.updateControllerStatus()
        }
        statusTimer?.resume()
    }

    private func updateControllerStatus() {
        if let gc = gamepadManager?.controller {
            controllerItem.title = gc.vendorName ?? gc.productCategory
        } else {
            controllerItem.title = "No controller"
        }
    }

    @objc private func toggleEnabled() {
        isEnabled = !isEnabled
        enabledItem.state = isEnabled ? .on : .off

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: isEnabled ? "gamecontroller.fill" : "gamecontroller",
                accessibilityDescription: "gpad2mouse"
            )
        }
        fputs("gpad2mouse: \(isEnabled ? "enabled" : "disabled")\n", stderr)
    }

    @objc private func toggleNaturalScroll() {
        naturalScroll = !naturalScroll
        naturalScrollItem.state = naturalScroll ? .on : .off
        fputs("gpad2mouse: natural scroll \(naturalScroll ? "on" : "off")\n", stderr)
    }

    @objc private func quit() {
        GCController.stopWirelessControllerDiscovery()
        fputs("gpad2mouse: shutting down\n", stderr)
        NSApp.terminate(nil)
    }
}
