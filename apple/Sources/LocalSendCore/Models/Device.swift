import Foundation

/// Represents a discovered LocalSend peer device on the local network.
public struct Device: Identifiable, Hashable, Sendable, Codable {
    public var id: String { fingerprint.isEmpty ? "\(ip):\(port)" : fingerprint }
    public let alias: String
    public let version: String
    public let deviceModel: String?
    public let deviceType: DeviceType
    public let fingerprint: String
    public let ip: String
    public let port: Int
    public let `protocol`: ProtocolType
    public let download: Bool
    public var lastSeen: Date

    public init(
        alias: String,
        version: String = "2.2",
        deviceModel: String? = nil,
        deviceType: DeviceType = .desktop,
        fingerprint: String,
        ip: String,
        port: Int = 53317,
        protocol: ProtocolType = .http,
        download: Bool = false,
        lastSeen: Date = Date()
    ) {
        self.alias = alias
        self.version = version
        self.deviceModel = deviceModel
        self.deviceType = deviceType
        self.fingerprint = fingerprint
        self.ip = ip
        self.port = port
        self.protocol = `protocol`
        self.download = download
        self.lastSeen = lastSeen
    }

    public var urlString: String {
        return "\(self.protocol.scheme)://\(ip):\(port)"
    }

    public var formattedAddress: String {
        return "\(ip):\(port)"
    }

    public static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
