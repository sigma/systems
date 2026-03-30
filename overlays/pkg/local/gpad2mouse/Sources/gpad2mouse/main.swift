import Foundation
import AppKit
import GameController

let config = Config.parse(CommandLine.arguments)

class AppDelegate: NSObject, NSApplicationDelegate {
    let gamepadManager = GamepadManager()
    let mouseEmitter = MouseEmitter()
    let appWatcher: AppWatcher
    let statusBar: StatusBar
    var pollTimer: DispatchSourceTimer?
    var sigintSource: DispatchSourceSignal?
    var sigtermSource: DispatchSourceSignal?
    var lastPollTime: CFAbsoluteTime = 0

    override init() {
        self.appWatcher = AppWatcher(excludedBundleIDs: config.excludedBundleIDs)
        self.statusBar = StatusBar(naturalScroll: config.naturalScroll)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        gamepadManager.debug = config.debug
        gamepadManager.start()
        appWatcher.start()
        statusBar.gamepadManager = gamepadManager
        statusBar.setup()

        if !AXIsProcessTrusted() {
            fputs("gpad2mouse: requesting Accessibility permission\n", stderr)
            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts)
        }

        fputs("gpad2mouse: running (poll=\(Int(1.0 / config.pollInterval))Hz, cursor=\(config.cursorSpeed), scroll=\(config.scrollSpeed))\n", stderr)
        if !config.excludedBundleIDs.isEmpty {
            fputs("gpad2mouse: excluded apps: \(config.excludedBundleIDs.joined(separator: ", "))\n", stderr)
        }

        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)
        sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main) as? DispatchSourceSignal
        sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main) as? DispatchSourceSignal
        sigintSource?.setEventHandler {
            GCController.stopWirelessControllerDiscovery()
            fputs("gpad2mouse: shutting down\n", stderr)
            NSApp.terminate(nil)
        }
        sigtermSource?.setEventHandler {
            GCController.stopWirelessControllerDiscovery()
            fputs("gpad2mouse: shutting down\n", stderr)
            NSApp.terminate(nil)
        }
        sigintSource?.resume()
        sigtermSource?.resume()

        pollTimer = DispatchSource.makeTimerSource(queue: .main) as? DispatchSourceTimer
        pollTimer?.schedule(deadline: .now(), repeating: config.pollInterval)
        pollTimer?.setEventHandler { [weak self] in
            self?.poll()
        }
        pollTimer?.resume()
    }

    func poll() {
        guard statusBar.isEnabled else { return }
        guard !appWatcher.isExcludedAppActive else { return }
        guard gamepadManager.controller != nil else { return }

        // Use actual elapsed time so movement is framerate-independent
        let now = CFAbsoluteTimeGetCurrent()
        let dt = lastPollTime == 0 ? config.pollInterval : min(now - lastPollTime, 0.1)
        lastPollTime = now

        let dz = config.deadzone

        // Left stick: fast cursor movement
        let (lx, ly) = gamepadManager.leftStick
        if abs(lx) > dz || abs(ly) > dz {
            let x = applyDeadzone(lx, dz)
            let y = applyDeadzone(ly, dz)
            let dx = Double(x) * config.cursorSpeed * dt
            let dy = Double(-y) * config.cursorSpeed * dt
            mouseEmitter.moveCursor(dx: dx, dy: dy)
        }

        // D-pad: slow, precise cursor movement
        let (dpx, dpy) = gamepadManager.dpad
        if abs(dpx) > 0.1 || abs(dpy) > 0.1 {
            let dx = Double(dpx) * config.dpadSpeed * dt
            let dy = Double(-dpy) * config.dpadSpeed * dt
            mouseEmitter.moveCursor(dx: dx, dy: dy)
        }

        // Right stick: scroll
        let (rx, ry) = gamepadManager.rightStick
        if abs(rx) > dz || abs(ry) > dz {
            let x = applyDeadzone(rx, dz)
            let y = applyDeadzone(ry, dz)
            let scrollDir: Double = statusBar.naturalScroll ? -1.0 : 1.0
            let sdx = Double(x) * config.scrollSpeed
            let sdy = Double(y) * config.scrollSpeed * scrollDir
            mouseEmitter.scroll(dx: sdx, dy: sdy)
        }

        // Buttons: mouse clicks
        mouseEmitter.updateButton(.left, pressed: gamepadManager.isButtonPressed(config.leftClickButton))
        mouseEmitter.updateButton(.right, pressed: gamepadManager.isButtonPressed(config.rightClickButton))
        mouseEmitter.updateButton(.middle, pressed: gamepadManager.isButtonPressed(config.middleClickButton))
    }
}

func applyDeadzone(_ value: Float, _ dz: Float) -> Float {
    if abs(value) <= dz { return 0 }
    let sign: Float = value > 0 ? 1 : -1
    return sign * (abs(value) - dz) / (1.0 - dz)
}

let delegate = AppDelegate()
let app = NSApplication.shared
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
