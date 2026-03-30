import SwiftUI
import Carbon.HIToolbox

struct ButtonMappingRow: View {
    let buttonName: String
    @Binding var action: ButtonAction
    let gamepadManager: GamepadManager

    @State private var isCapturing = false
    @State private var selectedActionType: ActionType

    enum ActionType: String, CaseIterable {
        case none = "None"
        case mouseClick = "Mouse Click"
        case modifierHold = "Modifier"
        case keyboardShortcut = "Keyboard Shortcut"
    }

    init(buttonName: String, action: Binding<ButtonAction>, gamepadManager: GamepadManager) {
        self.buttonName = buttonName
        self._action = action
        self.gamepadManager = gamepadManager
        self._selectedActionType = State(initialValue: ActionType.from(action.wrappedValue))
    }

    var body: some View {
        HStack {
            Text(Settings.buttonDisplayName(buttonName))
                .frame(width: 60, alignment: .leading)
                .fontWeight(.medium)

            Picker("", selection: $selectedActionType) {
                ForEach(ActionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .frame(width: 160)
            .onChange(of: selectedActionType) { newType in
                updateActionForType(newType)
            }

            Spacer()

            actionDetailView
        }
    }

    @ViewBuilder
    private var actionDetailView: some View {
        switch action {
        case .mouseClick(let button):
            Picker("", selection: mouseButtonBinding) {
                ForEach(MouseButton.allCases, id: \.self) { mb in
                    Text(mb.displayName).tag(mb)
                }
            }
            .frame(width: 120)

        case .modifierHold(let key):
            Picker("", selection: modifierKeyBinding) {
                ForEach(ModifierKey.allCases, id: \.self) { mk in
                    Text(mk.displayName).tag(mk)
                }
            }
            .frame(width: 120)

        case .keyboardShortcut(let combo):
            KeyComboRecorder(combo: keyComboBinding)
                .frame(width: 120)

        case .none:
            Text("—")
                .foregroundColor(.secondary)
                .frame(width: 120)
        }
    }

    private var mouseButtonBinding: Binding<MouseButton> {
        Binding(
            get: {
                if case .mouseClick(let mb) = action { return mb }
                return .left
            },
            set: { action = .mouseClick($0) }
        )
    }

    private var modifierKeyBinding: Binding<ModifierKey> {
        Binding(
            get: {
                if case .modifierHold(let mk) = action { return mk }
                return .command
            },
            set: { action = .modifierHold($0) }
        )
    }

    private var keyComboBinding: Binding<KeyCombo> {
        Binding(
            get: {
                if case .keyboardShortcut(let combo) = action { return combo }
                return KeyCombo(keyCode: 0, modifiers: 0, displayName: "")
            },
            set: { action = .keyboardShortcut($0) }
        )
    }

    private func updateActionForType(_ type: ActionType) {
        switch type {
        case .none: action = .none
        case .mouseClick: action = .mouseClick(.left)
        case .modifierHold: action = .modifierHold(.command)
        case .keyboardShortcut: action = .keyboardShortcut(KeyCombo(keyCode: 0, modifiers: 0, displayName: "Press key..."))
        }
    }
}

extension ButtonMappingRow.ActionType {
    static func from(_ action: ButtonAction) -> Self {
        switch action {
        case .mouseClick: return .mouseClick
        case .modifierHold: return .modifierHold
        case .keyboardShortcut: return .keyboardShortcut
        case .none: return .none
        }
    }
}

// MARK: - Key Combo Recorder

struct KeyComboRecorder: View {
    @Binding var combo: KeyCombo
    @State private var isRecording = false

    var body: some View {
        Button(action: { isRecording = true }) {
            Text(isRecording ? "Press key..." : (combo.displayName.isEmpty ? "Set key" : combo.displayName))
                .frame(maxWidth: .infinity)
                .foregroundColor(isRecording ? .orange : .primary)
        }
        .background(KeyEventCatcher(isRecording: $isRecording, combo: $combo))
    }
}

// NSView-based key event catcher for SwiftUI
struct KeyEventCatcher: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var combo: KeyCombo

    func makeNSView(context: Context) -> KeyCatcherView {
        let view = KeyCatcherView()
        view.onKeyDown = { event in
            guard isRecording else { return }
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let displayName = formatKeyCombo(keyCode: event.keyCode, modifiers: modifiers)
            combo = KeyCombo(
                keyCode: event.keyCode,
                modifiers: UInt64(modifiers.rawValue),
                displayName: displayName
            )
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: KeyCatcherView, context: Context) {
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    private func formatKeyCombo(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("^") }
        if modifiers.contains(.option) { parts.append("?") }
        if modifiers.contains(.shift) { parts.append("?") }
        if modifiers.contains(.command) { parts.append("?") }
        parts.append(keyCodeName(keyCode))
        return parts.joined()
    }

    private func keyCodeName(_ keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_Return: return "?"
        case kVK_Tab: return "?"
        case kVK_Space: return "Space"
        case kVK_Delete: return "?"
        case kVK_Escape: return "?"
        case kVK_LeftArrow: return "?"
        case kVK_RightArrow: return "?"
        case kVK_DownArrow: return "?"
        case kVK_UpArrow: return "?"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default:
            let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
            let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
            guard let data = layoutData else {
                return "Key\(keyCode)"
            }
            let layout = unsafeBitCast(data, to: CFData.self)
            let keyboardLayout = unsafeBitCast(CFDataGetBytePtr(layout), to: UnsafePointer<UCKeyboardLayout>.self)
            var deadKeyState: UInt32 = 0
            var chars = [UniChar](repeating: 0, count: 4)
            var length: Int = 0
            UCKeyTranslate(
                keyboardLayout,
                keyCode,
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )
            if length > 0 {
                return String(utf16CodeUnits: chars, count: length).uppercased()
            }
            return "Key\(keyCode)"
        }
    }
}

class KeyCatcherView: NSView {
    var onKeyDown: ((NSEvent) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        onKeyDown?(event)
    }
}
