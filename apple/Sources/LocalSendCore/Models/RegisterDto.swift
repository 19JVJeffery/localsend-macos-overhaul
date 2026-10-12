import Foundation

/// Register request DTO for v2.2 protocol.
/// Sent to POST /api/localsend/v2/register and broadcasted via UDP multicast.
public struct RegisterDto: Codable, Sendable, Equatable {
    public let alias: String
    public let version: String
    public let deviceModel: String?
    public let deviceType: DeviceType?
    public let fingerprint: String
    public let port: Int
    public let `protocol`: ProtocolType
    public let download: Bool

    public init(
        alias: String,
        version: String = "2.2",
        deviceModel: String? = nil,
        deviceType: DeviceType? = nil,
        fingerprint: String,
        port: Int = 53317,
        protocol: ProtocolType = .http,
        download: Bool = false
    ) {
        self.alias = alias
        self.version = version
        self.deviceModel = deviceModel
        self.deviceType = deviceType
        self.fingerprint = fingerprint
        self.port = port
        self.protocol = `protocol`
        self.download = download
    }
}

/// Register response DTO for v2.2 protocol.
public struct RegisterResponseDto: Codable, Sendable, Equatable {
    public let alias: String
    public let version: String
    public let deviceModel: String?
    public let deviceType: DeviceType?
    public let fingerprint: String
    public let download: Bool

    public init(
        alias: String,
        version: String = "2.2",
        deviceModel: String? = nil,
        deviceType: DeviceType? = nil,
        fingerprint: String,
        download: Bool = false
    ) {
        self.alias = alias
        self.version = version
        self.deviceModel = deviceModel
        self.deviceType = deviceType
        self.fingerprint = fingerprint
        self.download = download
    }

    enum CodingKeys: String, CodingKey {
        case alias
        case version
        case deviceModel
        case deviceType
        case fingerprint
        case download
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alias = try container.decode(String.self, forKey: .alias)
        version = try container.decode(String.self, forKey: .version)
        deviceModel = try container.decodeIfPresent(String.self, forKey: .deviceModel)
        deviceType = try container.decodeIfPresent(DeviceType.self, forKey: .deviceType)
        fingerprint = try container.decodeIfPresent(String.self, forKey: .fingerprint) ?? ""
        download = (try? container.decode(Bool.self, forKey: .download)) ?? false
    }
}

/// Info response DTO for GET /api/localsend/v2/info
public typealias InfoResponseDto = RegisterResponseDto
