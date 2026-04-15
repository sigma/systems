import Foundation
import CoreMIDI
import AppKit

// MARK: - Configuration

struct DeviceConfig: Codable {
    let name: String
    let host: String?
    let port: Int?
}

struct SessionConfig: Codable {
    let localName: String
    let networkName: String
    let port: Int
    let devices: [DeviceConfig]
}

struct Config: Codable {
    let hostname: String
    let pollInterval: Int?
    let sessions: [SessionConfig]
}

// MARK: - Logger

final class Logger {
    static let shared = Logger()
    private let maxSize = 1_048_576 // 1MB
    private var logPath: String?
    private var logFile: UnsafeMutablePointer<FILE>?

    func setup() {
        logPath = "\(NSHomeDirectory())/Library/Logs/midi-session-manager.log"
        guard let path = logPath else { return }
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir,
                                                  withIntermediateDirectories: true)
        logFile = fopen(path, "a")
    }

    func log(_ message: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let line = "[\(formatter.string(from: Date()))] \(message)\n"
        fputs(line, stderr)
        if let f = logFile {
            fputs(line, f)
            fflush(f)
        }
    }

    func truncateIfNeeded() {
        guard let f = logFile, let path = logPath else { return }
        var st = stat()
        if fstat(fileno(f), &st) == 0, st.st_size > off_t(maxSize) {
            fclose(f)
            logFile = fopen(path, "w")
            log("Log truncated (exceeded 1MB)")
        }
    }
}

private func log(_ message: String) { Logger.shared.log(message) }

// MARK: - CoreMIDI helpers

private let kRTPSessionKey = "apple.midirtp.session" as CFString

func getMIDIStringProperty(_ obj: MIDIObjectRef, _ prop: CFString) -> String? {
    var str: Unmanaged<CFString>?
    guard MIDIObjectGetStringProperty(obj, prop, &str) == noErr else { return nil }
    return str?.takeRetainedValue() as String?
}

func findNetworkDevice() -> MIDIDeviceRef? {
    for i in 0..<MIDIGetNumberOfDevices() {
        let device = MIDIGetDevice(i)
        guard getMIDIStringProperty(device, kMIDIPropertyDriverOwner)
                == "com.apple.AppleMIDINetworkDriver",
              getMIDIStringProperty(device, kMIDIPropertyName) != "UMP Network" else { continue }
        return device
    }
    return nil
}

func findEntity(device: MIDIDeviceRef, named name: String) -> MIDIEntityRef? {
    for i in 0..<MIDIDeviceGetNumberOfEntities(device) {
        let entity = MIDIDeviceGetEntity(device, i)
        if getMIDIStringProperty(entity, kMIDIPropertyName) == name {
            return entity
        }
    }
    return nil
}

func readSessionDict(_ entity: MIDIEntityRef) -> NSDictionary? {
    var dict: Unmanaged<CFDictionary>?
    guard MIDIObjectGetDictionaryProperty(entity, kRTPSessionKey, &dict) == noErr else { return nil }
    return dict?.takeRetainedValue() as NSDictionary?
}

func writeSessionDict(_ entity: MIDIEntityRef, _ dict: NSDictionary) -> Bool {
    MIDIObjectSetDictionaryProperty(entity, kRTPSessionKey, dict) == noErr
}

func hasPeer(named name: String, in peers: [[String: Any]]) -> Bool {
    peers.contains { ($0["name"] as? String)?.caseInsensitiveCompare(name) == .orderedSame }
}

// MARK: - Probe mode

func runProbe() -> Int32 {
    print("=== MIDI Devices ===")
    for i in 0..<MIDIGetNumberOfDevices() {
        let device = MIDIGetDevice(i)
        let name = getMIDIStringProperty(device, kMIDIPropertyName) ?? "?"
        let driver = getMIDIStringProperty(device, kMIDIPropertyDriverOwner) ?? "?"
        var offline: Int32 = 0
        MIDIObjectGetIntegerProperty(device, kMIDIPropertyOffline, &offline)
        print("Device \(i): \(name) (driver: \(driver), offline: \(offline))")

        for j in 0..<MIDIDeviceGetNumberOfEntities(device) {
            let entity = MIDIDeviceGetEntity(device, j)
            let eName = getMIDIStringProperty(entity, kMIDIPropertyName) ?? "?"
            print("  Entity \(j): \(eName)")

            if let sessionDict = readSessionDict(entity) {
                print("    RTP session: \(sessionDict)")
            }
        }
    }
    return 0
}

// MARK: - Session Manager

class MIDISessionManager: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    let config: Config
    let networkDevice: MIDIDeviceRef
    var browser: NetServiceBrowser?
    var activeServices: [String: NetService] = [:]
    var resolvedDevices: [String: [String: Any]] = [:]
    var healthCheckTimer: Timer?

    init(configPath: String) {
        let data = try! Data(contentsOf: URL(fileURLWithPath: configPath))
        config = try! JSONDecoder().decode(Config.self, from: data)
        guard let dev = findNetworkDevice() else {
            log("ERROR: Network MIDI device not found")
            exit(1)
        }
        networkDevice = dev
        super.init()
    }

    func start() {
        log("Starting MIDI session manager (\(config.sessions.count) session(s))")

        for session in config.sessions {
            let found = findEntity(device: networkDevice, named: session.localName) != nil
            log("  Session '\(session.localName)' -> \(found ? "entity found" : "NOT FOUND")")
            for dev in session.devices {
                let suffix = dev.host.map { " (static: \($0):\(dev.port ?? 5004))" } ?? ""
                log("    Device '\(dev.name)'\(suffix)")
            }
        }

        // Sleep/wake notifications
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(handleSleep),
                       name: NSWorkspace.willSleepNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleWake),
                       name: NSWorkspace.didWakeNotification, object: nil)

        connectStaticHosts()
        startBrowsing()

        let interval = TimeInterval(config.pollInterval ?? 30)
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.healthCheck()
        }

        log("Running (health check every \(Int(interval))s)")
    }

    // MARK: - Bonjour

    func startBrowsing() {
        browser = NetServiceBrowser()
        browser?.delegate = self
        browser?.searchForServices(ofType: "_apple-midi._udp", inDomain: "")
        log("Bonjour browsing started")
    }

    func stopBrowsing() {
        browser?.stop()
        browser = nil
        activeServices.values.forEach { $0.stop() }
        log("Bonjour browsing stopped")
    }

    private func isConfigured(_ name: String) -> Bool {
        config.sessions.flatMap(\.devices).contains {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService,
                           moreComing: Bool) {
        guard isConfigured(service.name) else { return }
        log("Discovered: \(service.name)")
        activeServices[service.name] = service
        service.delegate = self
        service.resolve(withTimeout: 10)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService,
                           moreComing: Bool) {
        guard isConfigured(service.name) else { return }
        log("Disappeared: \(service.name)")
        activeServices.removeValue(forKey: service.name)
        resolvedDevices.removeValue(forKey: service.name)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        let domain = sender.domain.isEmpty ? "local." : sender.domain
        log("Resolved \(sender.name) (domain: \(domain), port: \(sender.port))")

        // CoreMIDI uses Bonjour service references: \t<name>\t<domain>
        resolvedDevices[sender.name] = [
            "name": sender.name,
            "address": "\t\(sender.name)\t\(domain)",
        ]
        connectDevice(sender.name)
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        log("Resolve failed for \(sender.name): \(errorDict)")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser,
                           didNotSearch errorDict: [String: NSNumber]) {
        log("Browse failed: \(errorDict), retrying in 5s")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.startBrowsing()
        }
    }

    // MARK: - Connection management

    func connectStaticHosts() {
        for session in config.sessions {
            for dev in session.devices {
                guard let host = dev.host else { continue }
                let port = dev.port ?? 5004
                resolvedDevices[dev.name] = [
                    "name": dev.name,
                    "address": "\(host):\(port)",
                ]
                addPeer(dev.name, toSession: session.localName)
            }
        }
    }

    func connectDevice(_ deviceName: String) {
        for session in config.sessions {
            for dev in session.devices where dev.name.caseInsensitiveCompare(deviceName) == .orderedSame {
                addPeer(deviceName, toSession: session.localName)
            }
        }
    }

    func addPeer(_ deviceName: String, toSession sessionName: String) {
        guard let entity = findEntity(device: networkDevice, named: sessionName) else {
            log("Session '\(sessionName)' entity not found")
            return
        }
        guard let sessionDict = readSessionDict(entity) as? [String: Any] else {
            log("Cannot read session dict for '\(sessionName)'")
            return
        }
        let peers = sessionDict["peers"] as? [[String: Any]] ?? []
        guard !hasPeer(named: deviceName, in: peers) else { return }
        guard let peerInfo = resolvedDevices[deviceName] else {
            log("No resolved address for '\(deviceName)'")
            return
        }

        var newDict = sessionDict
        newDict["peers"] = peers + [peerInfo]

        if writeSessionDict(entity, newDict as NSDictionary) {
            log("Added '\(deviceName)' as peer to session '\(sessionName)'")
        } else {
            log("Failed to write peer for '\(deviceName)' to session '\(sessionName)'")
        }
    }

    // MARK: - Health check

    func healthCheck() {
        for session in config.sessions {
            guard let entity = findEntity(device: networkDevice, named: session.localName),
                  let sessionDict = readSessionDict(entity) as? [String: Any] else { continue }

            let peers = sessionDict["peers"] as? [[String: Any]] ?? []

            for dev in session.devices {
                guard resolvedDevices[dev.name] != nil else { continue }
                if !hasPeer(named: dev.name, in: peers) {
                    log("Health: '\(dev.name)' missing from '\(session.localName)', reconnecting")
                    addPeer(dev.name, toSession: session.localName)
                }
            }
        }
        Logger.shared.truncateIfNeeded()
    }

    // MARK: - Sleep/Wake

    @objc func handleSleep(_ note: Notification) {
        log("System sleeping, stopping browsing")
        stopBrowsing()
    }

    @objc func handleWake(_ note: Notification) {
        log("System woke, restarting in 5s")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            log("Restarting after wake")
            self?.startBrowsing()
            self?.healthCheck()
        }
    }
}

// MARK: - Main

func printUsage() {
    let prog = CommandLine.arguments[0]
    fputs("Usage:\n", stderr)
    fputs("  \(prog) --config <path>  Run daemon with config file\n", stderr)
    fputs("  \(prog) --probe          Dump CoreMIDI network session info\n", stderr)
}

let args = CommandLine.arguments
guard args.count >= 2 else { printUsage(); exit(1) }

switch args[1] {
case "--probe":
    exit(runProbe())

case "--config":
    guard args.count >= 3 else {
        fputs("Error: --config requires a path\n", stderr)
        exit(1)
    }
    Logger.shared.setup()
    let manager = MIDISessionManager(configPath: args[2])
    manager.start()
    RunLoop.current.run()

default:
    printUsage()
    exit(1)
}
