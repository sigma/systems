import Foundation
import GameController

class GamepadManager {
    private(set) var controller: GCController?

    var leftStick: (x: Float, y: Float) = (0, 0)
    var rightStick: (x: Float, y: Float) = (0, 0)
    var dpad: (x: Float, y: Float) = (0, 0)
    var pressedButtons: Set<String> = []

    var debug = false

    // Press-to-bind: when set, next button press calls this instead of normal tracking
    var buttonCaptureHandler: ((String) -> Void)?

    func start() {
        GCController.shouldMonitorBackgroundEvents = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerConnected),
            name: .GCControllerDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDisconnected),
            name: .GCControllerDidDisconnect,
            object: nil
        )
        GCController.startWirelessControllerDiscovery {}

        if let first = GCController.controllers().first {
            attachController(first)
        }
    }

    @objc private func controllerConnected(_ note: Notification) {
        guard let gc = note.object as? GCController else { return }
        if controller == nil {
            attachController(gc)
        }
    }

    @objc private func controllerDisconnected(_ note: Notification) {
        guard let gc = note.object as? GCController else { return }
        if controller === gc {
            controller = nil
            leftStick = (0, 0)
            rightStick = (0, 0)
            dpad = (0, 0)
            pressedButtons = []
            fputs("gpad2mouse: controller disconnected\n", stderr)
            if let next = GCController.controllers().first {
                attachController(next)
            }
        }
    }

    private func attachController(_ gc: GCController) {
        controller = gc
        fputs("gpad2mouse: connected to \(gc.vendorName ?? "unknown") (\(gc.productCategory))\n", stderr)
        setupHandlers(gc)
    }

    private func setupHandlers(_ gc: GCController) {
        guard let pad = gc.extendedGamepad else {
            fputs("gpad2mouse: warning - no extendedGamepad profile\n", stderr)
            return
        }

        pad.dpad.valueChangedHandler = { [weak self] _, x, y in
            self?.dpad = (x, y)
            if self?.debug == true { fputs("gpad2mouse: D(\(x), \(y))\n", stderr) }
        }

        pad.leftThumbstick.valueChangedHandler = { [weak self] _, x, y in
            self?.leftStick = (x, y)
            if self?.debug == true { fputs("gpad2mouse: L(\(x), \(y))\n", stderr) }
        }

        pad.rightThumbstick.valueChangedHandler = { [weak self] _, x, y in
            self?.rightStick = (x, y)
            if self?.debug == true { fputs("gpad2mouse: R(\(x), \(y))\n", stderr) }
        }

        let buttonNames: [(String, GCControllerButtonInput)] = [
            ("buttonA", pad.buttonA),
            ("buttonB", pad.buttonB),
            ("buttonX", pad.buttonX),
            ("buttonY", pad.buttonY),
            ("leftShoulder", pad.leftShoulder),
            ("rightShoulder", pad.rightShoulder),
            ("leftTrigger", pad.leftTrigger),
            ("rightTrigger", pad.rightTrigger),
            ("buttonMenu", pad.buttonMenu),
        ]
        if let opts = pad.buttonOptions {
            setupButton("buttonOptions", input: opts)
        }
        for (name, input) in buttonNames {
            setupButton(name, input: input)
        }
    }

    private func setupButton(_ name: String, input: GCControllerButtonInput) {
        input.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self = self else { return }
            // Press-to-bind capture: intercept on press, skip normal tracking
            if pressed, let handler = self.buttonCaptureHandler {
                self.buttonCaptureHandler = nil
                DispatchQueue.main.async { handler(name) }
                return
            }
            if pressed {
                self.pressedButtons.insert(name)
            } else {
                self.pressedButtons.remove(name)
            }
            if self.debug {
                fputs("gpad2mouse: \(name) \(pressed ? "down" : "up")\n", stderr)
            }
        }
    }

    func isButtonPressed(_ name: String) -> Bool {
        return pressedButtons.contains(name)
    }
}
