import Foundation
import AppKit
import GameController
import Combine

let config = Config.parse(CommandLine.arguments)
let settings = Settings(cliDefaults: config)

class AppDelegate: NSObject, NSApplicationDelegate {
    let gamepadManager = GamepadManager()
    let mouseEmitter = MouseEmitter()
    let appWatcher: AppWatcher
    let statusBar: StatusBar
    var pollTimer: DispatchSourceTimer?
    var sigintSource: DispatchSourceSignal?
    var sigtermSource: DispatchSourceSignal?
    var lastPollTime: CFAbsoluteTime = 0
    var cancellables = Set<AnyCancellable>()

    override init() {
        self.appWatcher = AppWatcher(excludedBundleIDs: Set(settings.excludedBundleIDs))
        self.statusBar = StatusBar()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        gamepadManager.debug = settings.debugLogging
        gamepadManager.start()
        appWatcher.start()
        statusBar.settings = settings
        statusBar.gamepadManager = gamepadManager
        statusBar.setup()

        if !AXIsProcessTrusted() {
            fputs("gpad2mouse: requesting Accessibility permission\n", stderr)
            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts)
        }

        fputs("gpad2mouse: running (poll=\(Int(settings.pollHz))Hz, cursor=\(settings.cursorSpeed), scroll=\(settings.scrollSpeed))\n", stderr)
        if !settings.excludedBundleIDs.isEmpty {
            fputs("gpad2mouse: excluded apps: \(settings.excludedBundleIDs.joined(separator: ", "))\n", stderr)
        }

        // Signal handling
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

        // Start poll timer
        startPollTimer()

        // Recreate timer when poll rate changes
        settings.$pollHz
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.startPollTimer() }
            .store(in: &cancellables)

        // Update AppWatcher when excluded apps change
        settings.$excludedBundleIDs
            .dropFirst()
            .sink { [weak self] ids in self?.appWatcher.excludedBundleIDs = Set(ids) }
            .store(in: &cancellables)

        // Update debug logging
        settings.$debugLogging
            .dropFirst()
            .sink { [weak self] debug in self?.gamepadManager.debug = debug }
            .store(in: &cancellables)
    }

    func startPollTimer() {
        pollTimer?.cancel()
        lastPollTime = 0
        pollTimer = DispatchSource.makeTimerSource(queue: .main) as? DispatchSourceTimer
        pollTimer?.schedule(deadline: .now(), repeating: settings.pollInterval)
        pollTimer?.setEventHandler { [weak self] in
            self?.poll()
        }
        pollTimer?.resume()
    }

    func poll() {
        guard statusBar.isEnabled else { return }
        guard !appWatcher.isExcludedAppActive else { return }
        guard gamepadManager.controller != nil else { return }

        // Framerate-independent timing
        let now = CFAbsoluteTimeGetCurrent()
        let dt = lastPollTime == 0 ? settings.pollInterval : min(now - lastPollTime, 0.1)
        lastPollTime = now

        let dz = Float(settings.deadzone)

        // Left stick: fast cursor movement
        let (lx, ly) = gamepadManager.leftStick
        if abs(lx) > dz || abs(ly) > dz {
            let x = applyDeadzone(lx, dz)
            let y = applyDeadzone(ly, dz)
            let dx = Double(x) * settings.cursorSpeed * dt
            let dy = Double(-y) * settings.cursorSpeed * dt
            mouseEmitter.moveCursor(dx: dx, dy: dy)
        }

        // D-pad: slow, precise cursor movement
        let (dpx, dpy) = gamepadManager.dpad
        if abs(dpx) > 0.1 || abs(dpy) > 0.1 {
            let dx = Double(dpx) * settings.dpadSpeed * dt
            let dy = Double(-dpy) * settings.dpadSpeed * dt
            mouseEmitter.moveCursor(dx: dx, dy: dy)
        }

        // Right stick: scroll
        let (rx, ry) = gamepadManager.rightStick
        if abs(rx) > dz || abs(ry) > dz {
            let x = applyDeadzone(rx, dz)
            let y = applyDeadzone(ry, dz)
            let scrollDir: Double = settings.naturalScroll ? -1.0 : 1.0
            let sdx = Double(x) * settings.scrollSpeed
            let sdy = Double(y) * settings.scrollSpeed * scrollDir
            mouseEmitter.scroll(dx: sdx, dy: sdy)
        }

        // Buttons: dispatch based on mappings
        // Skip button dispatch during press-to-bind capture
        guard gamepadManager.buttonCaptureHandler == nil else { return }

        for (buttonName, action) in settings.buttonMappings {
            let pressed = gamepadManager.isButtonPressed(buttonName)
            switch action {
            case .mouseClick(let mouseButton):
                mouseEmitter.updateButton(mouseButton, pressed: pressed)
            case .modifierHold(let key):
                mouseEmitter.updateModifier(key, pressed: pressed)
            case .keyboardShortcut(let combo):
                mouseEmitter.pressKey(combo, pressed: pressed)
            case .none:
                break
            }
        }
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
