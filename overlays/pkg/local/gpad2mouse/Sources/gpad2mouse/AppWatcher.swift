import AppKit

class AppWatcher {
    var excludedBundleIDs: Set<String> {
        didSet { checkFrontmostApp() }
    }
    private(set) var isExcludedAppActive: Bool = false
    private var observer: NSObjectProtocol?

    init(excludedBundleIDs: Set<String>) {
        self.excludedBundleIDs = excludedBundleIDs
    }

    func start() {
        checkFrontmostApp()

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkFrontmostApp()
        }
    }

    private func checkFrontmostApp() {
        let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        let wasExcluded = isExcludedAppActive
        isExcludedAppActive = excludedBundleIDs.contains(bundleID)

        if isExcludedAppActive != wasExcluded {
            if isExcludedAppActive {
                fputs("gpad2mouse: paused (gaming app: \(bundleID))\n", stderr)
            } else {
                fputs("gpad2mouse: resumed\n", stderr)
            }
        }
    }
}
