import Foundation

struct Config {
    let excludedBundleIDs: Set<String>
    let cursorSpeed: Double
    let dpadSpeed: Double
    let scrollSpeed: Double
    let pollInterval: TimeInterval
    let deadzone: Float
    let leftClickButton: String
    let rightClickButton: String
    let middleClickButton: String
    let naturalScroll: Bool
    let debug: Bool

    static func parse(_ args: [String]) -> Config {
        var excludedBundleIDs: Set<String> = []
        var cursorSpeed = 1500.0
        var dpadSpeed = 150.0
        var scrollSpeed = 8.0
        var pollHz = 120.0
        var deadzone: Float = 0.15
        var leftClick = "buttonA"
        var rightClick = "buttonB"
        var middleClick = "buttonX"
        var naturalScroll = false
        var debug = false

        var i = 1
        while i < args.count {
            switch args[i] {
            case "--exclude":
                i += 1
                if i < args.count {
                    for id in args[i].split(separator: ",") {
                        excludedBundleIDs.insert(String(id))
                    }
                }
            case "--cursor-speed":
                i += 1
                if i < args.count { cursorSpeed = Double(args[i]) ?? cursorSpeed }
            case "--dpad-speed":
                i += 1
                if i < args.count { dpadSpeed = Double(args[i]) ?? dpadSpeed }
            case "--scroll-speed":
                i += 1
                if i < args.count { scrollSpeed = Double(args[i]) ?? scrollSpeed }
            case "--poll-hz":
                i += 1
                if i < args.count { pollHz = Double(args[i]) ?? pollHz }
            case "--deadzone":
                i += 1
                if i < args.count { deadzone = Float(args[i]) ?? deadzone }
            case "--left-click":
                i += 1
                if i < args.count { leftClick = args[i] }
            case "--right-click":
                i += 1
                if i < args.count { rightClick = args[i] }
            case "--middle-click":
                i += 1
                if i < args.count { middleClick = args[i] }
            case "--natural-scroll":
                naturalScroll = true
            case "--debug":
                debug = true
            case "--help", "-h":
                printUsage()
                exit(0)
            default:
                fputs("Unknown option: \(args[i])\n", stderr)
                printUsage()
                exit(1)
            }
            i += 1
        }

        return Config(
            excludedBundleIDs: excludedBundleIDs,
            cursorSpeed: cursorSpeed,
            dpadSpeed: dpadSpeed,
            scrollSpeed: scrollSpeed,
            pollInterval: 1.0 / pollHz,
            deadzone: deadzone,
            leftClickButton: leftClick,
            rightClickButton: rightClick,
            middleClickButton: middleClick,
            naturalScroll: naturalScroll,
            debug: debug
        )
    }

    private static func printUsage() {
        let usage = """
            Usage: gpad2mouse [options]

            Options:
              --exclude <ids>       Comma-separated bundle IDs to disable in (e.g. com.valvesoftware.steam)
              --cursor-speed <n>    Pixels/sec at full stick deflection (default: 1500)
              --scroll-speed <n>    Scroll speed multiplier (default: 8)
              --poll-hz <n>         Polling rate in Hz (default: 120)
              --deadzone <n>        Stick deadzone 0.0-1.0 (default: 0.15)
              --left-click <btn>    Button for left click (default: buttonA)
              --right-click <btn>   Button for right click (default: buttonB)
              --middle-click <btn>  Button for middle click (default: buttonX)
              -h, --help            Show this help

            Button names: buttonA, buttonB, buttonX, buttonY,
                          leftShoulder, rightShoulder, leftTrigger, rightTrigger,
                          buttonMenu, buttonOptions
            """
        fputs(usage, stderr)
    }
}
