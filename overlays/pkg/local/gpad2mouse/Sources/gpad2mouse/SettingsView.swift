import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    let gamepadManager: GamepadManager

    var body: some View {
        Form {
            cursorSection
            scrollingSection
            buttonMappingSection
            excludedAppsSection
            advancedSection
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, minHeight: 500)
    }

    // MARK: - Cursor Control

    private var cursorSection: some View {
        Section("Cursor Control") {
            HStack {
                Text("Left Stick Speed")
                Spacer()
                Text("\(Int(settings.cursorSpeed))")
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $settings.cursorSpeed, in: 100...5000, step: 50)

            HStack {
                Text("D-pad Speed")
                Spacer()
                Text("\(Int(settings.dpadSpeed))")
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $settings.dpadSpeed, in: 10...500, step: 10)

            HStack {
                Text("Deadzone")
                Spacer()
                Text(String(format: "%.2f", settings.deadzone))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $settings.deadzone, in: 0.0...0.5, step: 0.01)
        }
    }

    // MARK: - Scrolling

    private var scrollingSection: some View {
        Section("Scrolling") {
            HStack {
                Text("Scroll Speed")
                Spacer()
                Text("\(Int(settings.scrollSpeed))")
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $settings.scrollSpeed, in: 1...30, step: 1)

            Toggle("Natural Scrolling", isOn: $settings.naturalScroll)
        }
    }

    // MARK: - Button Mapping

    private var buttonMappingSection: some View {
        Section("Button Mapping") {
            ForEach(Settings.allButtons, id: \.self) { buttonName in
                ButtonMappingRow(
                    buttonName: buttonName,
                    action: binding(for: buttonName),
                    gamepadManager: gamepadManager
                )
            }
        }
    }

    private func binding(for buttonName: String) -> Binding<ButtonAction> {
        Binding(
            get: { settings.buttonMappings[buttonName] ?? .none },
            set: { settings.buttonMappings[buttonName] = $0 }
        )
    }

    // MARK: - Excluded Apps

    private var excludedAppsSection: some View {
        Section("Excluded Apps") {
            ForEach(settings.excludedBundleIDs, id: \.self) { bundleID in
                HStack {
                    Text(bundleID)
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                    Button(role: .destructive) {
                        settings.excludedBundleIDs.removeAll { $0 == bundleID }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }
            }

            ExcludedAppAdder(excludedBundleIDs: $settings.excludedBundleIDs)
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        Section("Advanced") {
            HStack {
                Text("Poll Rate")
                Spacer()
                Text("\(Int(settings.pollHz)) Hz")
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $settings.pollHz, in: 30...240, step: 10)

            Toggle("Debug Logging", isOn: $settings.debugLogging)

            Button("Reset to Defaults") {
                settings.resetToDefaults()
            }
        }
    }
}

// MARK: - Excluded App Adder

struct ExcludedAppAdder: View {
    @Binding var excludedBundleIDs: [String]
    @State private var newBundleID = ""

    var body: some View {
        HStack {
            TextField("com.example.app", text: $newBundleID)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onSubmit { addApp() }
            Button("Add") { addApp() }
                .disabled(newBundleID.isEmpty)
        }
    }

    private func addApp() {
        let trimmed = newBundleID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !excludedBundleIDs.contains(trimmed) else { return }
        excludedBundleIDs.append(trimmed)
        newBundleID = ""
    }
}
