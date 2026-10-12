import Foundation

/// Represents the form-factor type of a LocalSend device.
public enum DeviceType: String, Codable, Sendable, CaseIterable {
    case mobile
    case desktop
    case web
    case headless
    case server

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let raw = try? container.decode(String.self).lowercased() {
            switch raw {
            case "mobile": self = .mobile
            case "desktop": self = .desktop
            case "web": self = .web
            case "headless": self = .headless
            case "server": self = .server
            default: self = .desktop
            }
        } else {
            self = .desktop
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var displayName: String {
        switch self {
        case .mobile: return "Mobile"
        case .desktop: return "Desktop"
        case .web: return "Web"
        case .headless: return "Headless"
        case .server: return "Server"
        }
    }

    public var systemImageName: String {
        switch self {
        case .mobile: return "iphone"
        case .desktop: return "macbook"
        case .web: return "globe"
        case .headless: return "cpu"
        case .server: return "server.rack"
        }
    }
}
