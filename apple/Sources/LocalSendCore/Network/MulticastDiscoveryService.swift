import Foundation
import Network

/// Discovers other LocalSend peers and announces this device using UDP multicast & broadcast.
public final class MulticastDiscoveryService: @unchecked Sendable {
    public static let defaultMulticastGroup = "224.0.0.167"
    public static let defaultPort: UInt16 = 53317

    private let queue = DispatchQueue(label: "org.localsend.multicast", qos: .utility)
    private var listener: NWListener?
    private var isRunning = false
    private var announceTimer: DispatchSourceTimer?

    public var onDeviceDiscovered: (@Sendable (Device) -> Void)?

    public init() {}

    /// Starts listening for announcements on UDP port 53317.
    public func startListening(port: UInt16 = defaultPort) {
        guard !isRunning else { return }
        isRunning = true

        do {
            let parameters = NWParameters.udp
            parameters.allowLocalEndpointReuse = true

            // Set up listener
            guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
            let newListener = try NWListener(using: parameters, on: nwPort)
            self.listener = newListener

            newListener.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }

            newListener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("[LocalSend Multicast] Listener ready on port \(port)")
                case .failed(let error):
                    print("[LocalSend Multicast] Listener failed: \(error)")
                default:
                    break
                }
            }

            newListener.start(queue: queue)
        } catch {
            print("[LocalSend Multicast] Failed to start listener: \(error)")
        }
    }

    /// Stops the listener and announcement timers.
    public func stop() {
        isRunning = false
        announceTimer?.cancel()
        announceTimer = nil
        listener?.cancel()
        listener = nil
    }

    /// Starts a periodic announcement timer.
    public func startPeriodicAnnounce(registerDto: RegisterDto, intervalSeconds: TimeInterval = 10.0) {
        announceTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: intervalSeconds)
        timer.setEventHandler { [weak self] in
            self?.announce(registerDto: registerDto)
        }
        timer.resume()
        self.announceTimer = timer
    }

    /// Broadcasts an announcement to the local network.
    public func announce(registerDto: RegisterDto) {
        guard let data = try? JSONEncoder().encode(registerDto) else { return }

        // Send to standard multicast group
        sendUDP(data: data, host: Self.defaultMulticastGroup, port: Self.defaultPort)

        // Also send to 255.255.255.255 and subnet broadcast addresses for routers blocking multicast
        sendUDP(data: data, host: "255.255.255.255", port: Self.defaultPort)

        let localInterfaces = NetworkAddressHelper.getLocalIPv4Addresses()
        for iface in localInterfaces {
            if let broadcast = iface.broadcast {
                sendUDP(data: data, host: broadcast, port: Self.defaultPort)
            }
        }
    }

    private func sendUDP(data: Data, host: String, port: UInt16) {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: nwPort)
        let connection = NWConnection(to: endpoint, using: .udp)

        connection.stateUpdateHandler = { state in
            if case .ready = state {
                connection.send(content: data, completion: .contentProcessed { _ in
                    connection.cancel()
                })
            } else if case .failed = state {
                connection.cancel()
            }
        }

        connection.start(queue: queue)
    }

    private func handleIncomingConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveNextPacket(connection: connection)
    }

    private func receiveNextPacket(connection: NWConnection) {
        connection.receiveMessage { [weak self] content, context, isComplete, error in
            guard let self = self else { return }

            if let data = content, !data.isEmpty {
                var peerIP: String = ""
                if case let .hostPort(host, _) = connection.endpoint {
                    switch host {
                    case .ipv4(let addr): peerIP = "\(addr)"
                    case .ipv6(let addr): peerIP = "\(addr)"
                    case .name(let name, _): peerIP = name
                    @unknown default: break
                    }
                }

                self.parsePacket(data: data, peerIP: peerIP)
            }

            if error == nil && !isComplete {
                self.receiveNextPacket(connection: connection)
            } else {
                connection.cancel()
            }
        }
    }

    private func parsePacket(data: Data, peerIP: String) {
        guard let dto = try? JSONDecoder().decode(RegisterDto.self, from: data) else {
            return
        }

        // Ignore our own announcement
        let myFingerprint = FingerprintHelper.getOrCreateFingerprint()
        if dto.fingerprint == myFingerprint {
            return
        }

        let device = Device(
            alias: dto.alias,
            version: dto.version,
            deviceModel: dto.deviceModel,
            deviceType: dto.deviceType ?? .desktop,
            fingerprint: dto.fingerprint,
            ip: peerIP.isEmpty ? "127.0.0.1" : peerIP,
            port: dto.port,
            protocol: dto.protocol,
            download: dto.download,
            lastSeen: Date()
        )

        DispatchQueue.main.async {
            self.onDeviceDiscovered?(device)
        }
    }
}
