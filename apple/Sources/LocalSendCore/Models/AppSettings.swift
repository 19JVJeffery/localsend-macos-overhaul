import Foundation

public enum AccentColorPreference: String, Codable, Sendable, CaseIterable {
    case localSend = "localsend"
    case system = "system"

    public var displayName: String {
        switch self {
        case .localSend: return "Original LocalSend"
        case .system: return "Match System Accent"
        }
    }

    public var subtitle: String {
        switch self {
        case .localSend: return "Signature LocalSend Teal palette (#009688 / #008080)"
        case .system: return "Follows your device's System Settings accent colour"
        }
    }
}

/// Application settings persisted across app launches.
public struct AppSettings: Codable, Sendable {
    public var alias: String
    public var deviceType: DeviceType
    public var port: Int
    public var multicastGroup: String
    public var multicastPort: Int
    public var autoAccept: Bool
    public var destinationDirectoryPath: String
    public var protocolType: ProtocolType
    public var saveToHistory: Bool
    public var accentColorPreference: AccentColorPreference

    public static var defaultDestinationDirectory: URL {
        #if os(macOS)
        return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        #else
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        #endif
    }

    public static var defaultAlias: String {
        #if os(macOS)
        let host = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        return host.replacingOccurrences(of: ".local", with: "")
        #else
        #if targetEnvironment(macCatalyst)
        return "Mac"
        #else
        return "Apple Device"
        #endif
        #endif
    }

    public static var defaultDeviceType: DeviceType {
        #if os(macOS)
        return .desktop
        #else
        return .mobile
        #endif
    }

    public init(
        alias: String = defaultAlias,
        deviceType: DeviceType = defaultDeviceType,
        port: Int = 53317,
        multicastGroup: String = "224.0.0.167",
        multicastPort: Int = 53317,
        autoAccept: Bool = false,
        destinationDirectoryPath: String = defaultDestinationDirectory.path,
        protocolType: ProtocolType = .http,
        saveToHistory: Bool = true,
        accentColorPreference: AccentColorPreference = .localSend
    ) {
        self.alias = alias
        self.deviceType = deviceType
        self.port = port
        self.multicastGroup = multicastGroup
        self.multicastPort = multicastPort
        self.autoAccept = autoAccept
        self.destinationDirectoryPath = destinationDirectoryPath
        self.protocolType = protocolType
        self.saveToHistory = saveToHistory
        self.accentColorPreference = accentColorPreference
    }

    public var destinationURL: URL {
        URL(fileURLWithPath: destinationDirectoryPath)
    }

    enum CodingKeys: String, CodingKey {
        case alias, deviceType, port, multicastGroup, multicastPort
        case autoAccept, destinationDirectoryPath, protocolType, saveToHistory
        case accentColorPreference
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alias = try container.decodeIfPresent(String.self, forKey: .alias) ?? Self.defaultAlias
        deviceType = try container.decodeIfPresent(DeviceType.self, forKey: .deviceType) ?? Self.defaultDeviceType
        port = try container.decodeIfPresent(Int.self, forKey: .port) ?? 53317
        multicastGroup = try container.decodeIfPresent(String.self, forKey: .multicastGroup) ?? "224.0.0.167"
        multicastPort = try container.decodeIfPresent(Int.self, forKey: .multicastPort) ?? 53317
        autoAccept = try container.decodeIfPresent(Bool.self, forKey: .autoAccept) ?? false
        destinationDirectoryPath = try container.decodeIfPresent(String.self, forKey: .destinationDirectoryPath) ?? Self.defaultDestinationDirectory.path
        protocolType = try container.decodeIfPresent(ProtocolType.self, forKey: .protocolType) ?? .http
        saveToHistory = try container.decodeIfPresent(Bool.self, forKey: .saveToHistory) ?? true
        accentColorPreference = try container.decodeIfPresent(AccentColorPreference.self, forKey: .accentColorPreference) ?? .localSend
    }

    private static let userDefaultsKey = "localsend_app_settings"

    public static func load() -> AppSettings {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return settings
        }
        return AppSettings()
    }

    public func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}
