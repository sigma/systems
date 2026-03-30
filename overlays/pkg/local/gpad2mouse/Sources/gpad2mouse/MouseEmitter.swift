import CoreGraphics
import Foundation

class MouseEmitter {
    private var cursorPos: CGPoint
    private var leftDown = false
    private var rightDown = false
    private var middleDown = false

    init() {
        if let event = CGEvent(source: nil) {
            cursorPos = event.location
        } else {
            cursorPos = CGPoint(x: 500, y: 500)
        }
    }

    func moveCursor(dx: Double, dy: Double) {
        // Refresh position from system to stay in sync with real mouse
        if let event = CGEvent(source: nil) {
            cursorPos = event.location
        }

        cursorPos.x += dx
        cursorPos.y += dy
        clampToScreenBounds()

        // Use the appropriate move event type depending on button state
        let eventType: CGEventType = leftDown ? .leftMouseDragged
            : rightDown ? .rightMouseDragged
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
        let wasPressed: Bool
        switch button {
        case .left: wasPressed = leftDown
        case .right: wasPressed = rightDown
        case .middle: wasPressed = middleDown
        }

        guard pressed != wasPressed else { return }

        // Refresh cursor position
        if let event = CGEvent(source: nil) {
            cursorPos = event.location
        }

        let eventType: CGEventType
        let cgButton: CGMouseButton

        switch (button, pressed) {
        case (.left, true): eventType = .leftMouseDown; cgButton = .left
        case (.left, false): eventType = .leftMouseUp; cgButton = .left
        case (.right, true): eventType = .rightMouseDown; cgButton = .right
        case (.right, false): eventType = .rightMouseUp; cgButton = .right
        case (.middle, true): eventType = .otherMouseDown; cgButton = .center
        case (.middle, false): eventType = .otherMouseUp; cgButton = .center
        }

        guard let clickEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: eventType,
            mouseCursorPosition: cursorPos,
            mouseButton: cgButton
        ) else { return }

        if button == .middle {
            clickEvent.setIntegerValueField(.mouseEventButtonNumber, value: 2)
        }

        clickEvent.post(tap: .cgSessionEventTap)

        switch button {
        case .left: leftDown = pressed
        case .right: rightDown = pressed
        case .middle: middleDown = pressed
        }
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

    enum MouseButton {
        case left, right, middle
    }
}
