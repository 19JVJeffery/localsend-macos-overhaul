import Foundation

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
        saveToHistory: Bool = true
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
    }

    public var destinationURL: URL {
        URL(fileURLWithPath: destinationDirectoryPath)
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
