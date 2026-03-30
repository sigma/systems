import CoreGraphics
import Foundation

class MouseEmitter {
    private var cursorPos: CGPoint

    // Button state tracking
    private var buttonState: [MouseButton: Bool] = [
        .left: false, .right: false, .middle: false, .back: false, .forward: false,
    ]

    // Modifier state tracking
    private var activeModifiers: CGEventFlags = []
    private var heldModifiers: [ModifierKey: Bool] = [:]

    // Key state tracking (prevent repeated key-down events)
    private var heldKeys: Set<String> = []

    init() {
        if let event = CGEvent(source: nil) {
            cursorPos = event.location
        } else {
            cursorPos = CGPoint(x: 500, y: 500)
        }
    }

    func moveCursor(dx: Double, dy: Double) {
        if let event = CGEvent(source: nil) {
            cursorPos = event.location
        }

        cursorPos.x += dx
        cursorPos.y += dy
        clampToScreenBounds()

        let eventType: CGEventType = buttonState[.left] == true ? .leftMouseDragged
            : buttonState[.right] == true ? .rightMouseDragged
            : .mouseMoved

        guard let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: eventType,
            mouseCursorPosition: cursorPos,
            mouseButton: .left
        ) else { return }

        moveEvent.post(tap: .cgSessionEventTap)
    }

    func scroll(dx: Double, dy: Double) {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(dy),
            wheel2: Int32(dx),
            wheel3: 0
        ) else { return }

        event.post(tap: .cgSessionEventTap)
    }

    func updateButton(_ button: MouseButton, pressed: Bool) {
        let wasPressed = buttonState[button] ?? false
        guard pressed != wasPressed else { return }

        if let event = CGEvent(source: nil) {
            cursorPos = event.location
        }

        let eventType: CGEventType
        let cgButton: CGMouseButton
        let buttonNumber: Int64?

        switch (button, pressed) {
        case (.left, true):    eventType = .leftMouseDown;  cgButton = .left;   buttonNumber = nil
        case (.left, false):   eventType = .leftMouseUp;    cgButton = .left;   buttonNumber = nil
        case (.right, true):   eventType = .rightMouseDown;  cgButton = .right;  buttonNumber = nil
        case (.right, false):  eventType = .rightMouseUp;    cgButton = .right;  buttonNumber = nil
        case (.middle, true):  eventType = .otherMouseDown;  cgButton = .center; buttonNumber = 2
        case (.middle, false): eventType = .otherMouseUp;    cgButton = .center; buttonNumber = 2
        case (.back, true):    eventType = .otherMouseDown;  cgButton = .center; buttonNumber = 3
        case (.back, false):   eventType = .otherMouseUp;    cgButton = .center; buttonNumber = 3
        case (.forward, true):  eventType = .otherMouseDown; cgButton = .center; buttonNumber = 4
        case (.forward, false): eventType = .otherMouseUp;   cgButton = .center; buttonNumber = 4
        }

        guard let clickEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: eventType,
            mouseCursorPosition: cursorPos,
            mouseButton: cgButton
        ) else { return }

        if let num = buttonNumber {
            clickEvent.setIntegerValueField(.mouseEventButtonNumber, value: num)
        }

        clickEvent.post(tap: .cgSessionEventTap)
        buttonState[button] = pressed
    }

    func updateModifier(_ key: ModifierKey, pressed: Bool) {
        let wasPressed = heldModifiers[key] ?? false
        guard pressed != wasPressed else { return }
        heldModifiers[key] = pressed

        // Recompute combined modifier flags
        var flags: CGEventFlags = []
        for (k, held) in heldModifiers where held {
            flags.insert(k.cgEventFlag)
        }
        activeModifiers = flags

        guard let event = CGEvent(source: nil) else { return }
        event.type = .flagsChanged
        event.flags = activeModifiers
        event.post(tap: .cgSessionEventTap)
    }

    func pressKey(_ combo: KeyCombo, pressed: Bool) {
        let key = "\(combo.keyCode)-\(combo.modifiers)"
        let wasPressed = heldKeys.contains(key)
        guard pressed != wasPressed else { return }

        if pressed {
            heldKeys.insert(key)
        } else {
            heldKeys.remove(key)
        }

        guard let event = CGEvent(
            keyboardEventSource: nil,
            virtualKey: combo.keyCode,
            keyDown: pressed
        ) else { return }

        event.flags = CGEventFlags(rawValue: combo.modifiers).union(activeModifiers)
        event.post(tap: .cgSessionEventTap)
    }

    private func clampToScreenBounds() {
        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var maxY = -CGFloat.infinity

        let maxDisplays: UInt32 = 16
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(maxDisplays, &displays, &displayCount)

        for i in 0..<Int(displayCount) {
            let bounds = CGDisplayBounds(displays[i])
            minX = min(minX, bounds.minX)
            minY = min(minY, bounds.minY)
            maxX = max(maxX, bounds.maxX)
            maxY = max(maxY, bounds.maxY)
        }

        cursorPos.x = max(minX, min(maxX - 1, cursorPos.x))
        cursorPos.y = max(minY, min(maxY - 1, cursorPos.y))
    }
}
