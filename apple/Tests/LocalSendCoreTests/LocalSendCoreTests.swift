import XCTest
@testable import LocalSendCore

final class LocalSendCoreTests: XCTestCase {

    func testRegisterDtoEncodingDecoding() throws {
        let original = RegisterDto(
            alias: "MacBook Pro",
            version: "2.2",
            deviceModel: "MacBookPro18,1",
            deviceType: .desktop,
            fingerprint: "abc123def456",
            port: 53317,
            protocol: .http,
            download: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RegisterDto.self, from: data)

        XCTAssertEqual(decoded.alias, "MacBook Pro")
        XCTAssertEqual(decoded.version, "2.2")
        XCTAssertEqual(decoded.deviceModel, "MacBookPro18,1")
        XCTAssertEqual(decoded.deviceType, .desktop)
        XCTAssertEqual(decoded.fingerprint, "abc123def456")
        XCTAssertEqual(decoded.port, 53317)
        XCTAssertEqual(decoded.protocol, .http)
        XCTAssertFalse(decoded.download)
    }

    func testDeviceTypeUnknownFallsBackToDesktop() throws {
        let json = """
        {
            "alias": "Mystery Device",
            "version": "2.2",
            "deviceType": "smart-fridge",
            "fingerprint": "xyz789",
            "port": 53317,
            "protocol": "http",
            "download": false
        }
        """

        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(RegisterDto.self, from: data)

        XCTAssertEqual(decoded.deviceType, .desktop, "Protocol specifies that unknown device types must fall back to desktop")
    }

    func testPrepareUploadDtoRoundTrip() throws {
        let info = RegisterDto(
            alias: "iPhone Sender",
            version: "2.2",
            deviceModel: "iPhone15,2",
            deviceType: .mobile,
            fingerprint: "sender-fp",
            port: 53317,
            protocol: .http,
            download: false
        )

        let file = FileDto(
            id: "file-1",
            fileName: "photo.jpg",
            size: 204800,
            fileType: "image/jpeg"
        )

        let request = PrepareUploadRequestDto(info: info, files: ["file-1": file])
        let data = try JSONEncoder().encode(request)

        let decoded = try JSONDecoder().decode(PrepareUploadRequestDto.self, from: data)
        XCTAssertEqual(decoded.info.alias, "iPhone Sender")
        XCTAssertEqual(decoded.files["file-1"]?.fileName, "photo.jpg")
        XCTAssertEqual(decoded.files["file-1"]?.size, 204800)
    }

    func testPrepareUploadResponseDto() throws {
        let response = PrepareUploadResponseDto(
            sessionId: "session-1234",
            files: ["file-1": "token-abcd"]
        )

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(PrepareUploadResponseDto.self, from: data)

        XCTAssertEqual(decoded.sessionId, "session-1234")
        XCTAssertEqual(decoded.files["file-1"], "token-abcd")
    }

    func testFingerprintHelperGeneratesNonEmptyString() {
        let fp = FingerprintHelper.getOrCreateFingerprint()
        XCTAssertFalse(fp.isEmpty)
        XCTAssertEqual(fp.count, 32)
    }

    func testDeviceFormatting() {
        let device = Device(
            alias: "Studio Mac",
            deviceType: .desktop,
            fingerprint: "fp-1",
            ip: "192.168.1.100",
            port: 53317,
            protocol: .http
        )

        XCTAssertEqual(device.urlString, "http://192.168.1.100:53317")
        XCTAssertEqual(device.formattedAddress, "192.168.1.100:53317")
    }

    func testAccentColorPreferenceDefaultAndMigration() throws {
        // 1. Default should be localSend
        let settings = AppSettings()
        XCTAssertEqual(settings.accentColorPreference, .localSend)

        // 2. Backward compatibility: JSON missing accentColorPreference should decode as .localSend
        let legacyJson = """
        {
            "alias": "Legacy Mac",
            "deviceType": "desktop",
            "port": 53317,
            "multicastGroup": "224.0.0.167",
            "multicastPort": 53317,
            "autoAccept": false,
            "destinationDirectoryPath": "/tmp",
            "protocolType": "http",
            "saveToHistory": true
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AppSettings.self, from: legacyJson)
        XCTAssertEqual(decoded.accentColorPreference, .localSend, "Missing preference should default to localSend")
    }

    @MainActor
    func testTextMessageStaging() throws {
        let engine = LocalSendEngine()
        engine.clearStagedFiles()
        XCTAssertTrue(engine.stagedFiles.isEmpty)

        engine.stageTextMessage("Hello from LocalSend Apple!")
        XCTAssertEqual(engine.stagedFiles.count, 1)

        let file = engine.stagedFiles.first!
        XCTAssertEqual(file.fileExtension, "txt")
        XCTAssertTrue(file.name.hasPrefix("message-"))

        let content = try String(contentsOf: file.url, encoding: .utf8)
        XCTAssertEqual(content, "Hello from LocalSend Apple!")
    }

    func testThemeModePreferenceDefaultAndMigration() throws {
        let settings = AppSettings()
        XCTAssertEqual(settings.themeMode, .system)

        let legacyJson = """
        {
            "alias": "Legacy Mac",
            "deviceType": "desktop",
            "port": 53317,
            "multicastGroup": "224.0.0.167",
            "multicastPort": 53317,
            "autoAccept": false,
            "destinationDirectoryPath": "/tmp",
            "protocolType": "http",
            "saveToHistory": true
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AppSettings.self, from: legacyJson)
        XCTAssertEqual(decoded.themeMode, .system)
    }

    func testDeleteHistoryItem() throws {
        let manager = TransferHistoryManager.shared
        manager.clearHistory()
        XCTAssertTrue(manager.loadHistory().isEmpty)

        let item = TransferHistoryItem(
            remoteDeviceAlias: "iPhone",
            remoteDeviceType: .mobile,
            direction: .receiving,
            fileCount: 1,
            totalSize: 120,
            status: .completed,
            date: Date(),
            fileNames: ["note.txt"],
            destinationPaths: ["/tmp/note.txt"]
        )

        manager.addHistoryItem(item)
        XCTAssertEqual(manager.loadHistory().count, 1)

        manager.deleteItem(id: item.id)
        XCTAssertEqual(manager.loadHistory().count, 0)
    }
}
