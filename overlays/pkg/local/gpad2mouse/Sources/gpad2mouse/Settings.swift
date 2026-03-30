import Foundation
import CoreGraphics
import Combine

// MARK: - Action Types

enum MouseButton: String, Codable, CaseIterable, Hashable {
    case left, right, middle, back, forward

    var displayName: String {
        switch self {
        case .left: return "Left Click"
        case .right: return "Right Click"
        case .middle: return "Middle Click"
        case .back: return "Back"
        case .forward: return "Forward"
        }
    }
}

struct KeyCombo: Codable, Hashable {
    let keyCode: UInt16
    let modifiers: UInt64
    let displayName: String
}

enum ModifierKey: String, Codable, CaseIterable, Hashable {
    case command, control, option, shift

    var displayName: String {
        switch self {
        case .command: return "Command"
        case .control: return "Control"
        case .option: return "Option"
        case .shift: return "Shift"
        }
    }

    var cgEventFlag: CGEventFlags {
        switch self {
        case .command: return .maskCommand
        case .control: return .maskControl
        case .option: return .maskAlternate
        case .shift: return .maskShift
        }
    }
}

enum ButtonAction: Codable, Hashable {
    case mouseClick(MouseButton)
    case modifierHold(ModifierKey)
    case keyboardShortcut(KeyCombo)
    case none
}

// MARK: - Settings

class Settings: ObservableObject {
    private let cliDefaults: Config

    @Published var cursorSpeed: Double {
        didSet { UserDefaults.standard.set(cursorSpeed, forKey: "cursorSpeed") }
    }
    @Published var dpadSpeed: Double {
        didSet { UserDefaults.standard.set(dpadSpeed, forKey: "dpadSpeed") }
    }
    @Published var scrollSpeed: Double {
        didSet { UserDefaults.standard.set(scrollSpeed, forKey: "scrollSpeed") }
    }
    @Published var deadzone: Double {
        didSet { UserDefaults.standard.set(deadzone, forKey: "deadzone") }
    }
    @Published var pollHz: Double {
        didSet { UserDefaults.standard.set(pollHz, forKey: "pollHz") }
    }
    @Published var naturalScroll: Bool {
        didSet { UserDefaults.standard.set(naturalScroll, forKey: "naturalScroll") }
    }
    @Published var debugLogging: Bool {
        didSet { UserDefaults.standard.set(debugLogging, forKey: "debugLogging") }
    }
    @Published var excludedBundleIDs: [String] {
        didSet { UserDefaults.standard.set(excludedBundleIDs, forKey: "excludedBundleIDs") }
    }
    @Published var buttonMappings: [String: ButtonAction] {
        didSet { saveButtonMappings() }
    }

    var pollInterval: TimeInterval { 1.0 / pollHz }

    init(cliDefaults: Config) {
        self.cliDefaults = cliDefaults
        let ud = UserDefaults.standard

        self.cursorSpeed = ud.object(forKey: "cursorSpeed") as? Double ?? cliDefaults.cursorSpeed
        self.dpadSpeed = ud.object(forKey: "dpadSpeed") as? Double ?? cliDefaults.dpadSpeed
        self.scrollSpeed = ud.object(forKey: "scrollSpeed") as? Double ?? cliDefaults.scrollSpeed
        self.deadzone = ud.object(forKey: "deadzone") as? Double ?? Double(cliDefaults.deadzone)
        self.pollHz = ud.object(forKey: "pollHz") as? Double ?? (1.0 / cliDefaults.pollInterval)
        self.naturalScroll = ud.object(forKey: "naturalScroll") as? Bool ?? cliDefaults.naturalScroll
        self.debugLogging = ud.object(forKey: "debugLogging") as? Bool ?? cliDefaults.debug
        self.excludedBundleIDs = ud.object(forKey: "excludedBundleIDs") as? [String]
            ?? Array(cliDefaults.excludedBundleIDs)

        // Button mappings: load from UserDefaults or build from CLI defaults
        if let data = ud.data(forKey: "buttonMappings"),
           let decoded = try? JSONDecoder().decode([String: ButtonAction].self, from: data) {
            self.buttonMappings = decoded
        } else {
            self.buttonMappings = Self.defaultMappings(from: cliDefaults)
        }
    }

    func resetToDefaults() {
        let keys = ["cursorSpeed", "dpadSpeed", "scrollSpeed", "deadzone", "pollHz",
                     "naturalScroll", "debugLogging", "buttonMappings", "excludedBundleIDs"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }

        cursorSpeed = cliDefaults.cursorSpeed
        dpadSpeed = cliDefaults.dpadSpeed
        scrollSpeed = cliDefaults.scrollSpeed
        deadzone = Double(cliDefaults.deadzone)
        pollHz = 1.0 / cliDefaults.pollInterval
        naturalScroll = cliDefaults.naturalScroll
        debugLogging = cliDefaults.debug
        excludedBundleIDs = Array(cliDefaults.excludedBundleIDs)
        buttonMappings = Self.defaultMappings(from: cliDefaults)
    }

    private func saveButtonMappings() {
        if let data = try? JSONEncoder().encode(buttonMappings) {
            UserDefaults.standard.set(data, forKey: "buttonMappings")
        }
    }

    private static func defaultMappings(from config: Config) -> [String: ButtonAction] {
        return [
            config.leftClickButton: .mouseClick(.left),
            config.rightClickButton: .mouseClick(.right),
            config.middleClickButton: .mouseClick(.middle),
        ]
    }

    // All gamepad buttons available for mapping
    static let allButtons = [
        "buttonA", "buttonB", "buttonX", "buttonY",
        "leftShoulder", "rightShoulder",
        "leftTrigger", "rightTrigger",
        "buttonMenu", "buttonOptions",
    ]

    static func buttonDisplayName(_ name: String) -> String {
        switch name {
        case "buttonA": return "A"
        case "buttonB": return "B"
        case "buttonX": return "X"
        case "buttonY": return "Y"
        case "leftShoulder": return "LB"
        case "rightShoulder": return "RB"
        case "leftTrigger": return "LT"
        case "rightTrigger": return "RT"
        case "buttonMenu": return "Menu"
        case "buttonOptions": return "Options"
        default: return name
        }
    }
}
