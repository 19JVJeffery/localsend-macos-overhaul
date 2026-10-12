import Foundation
import Combine

/// Central coordinator managing networking, state, staged files, discovery, and file transfers.
@MainActor
public final class LocalSendEngine: ObservableObject {
    public static let shared = LocalSendEngine()

    @Published public var discoveredDevices: [Device] = []
    @Published public var stagedFiles: [StagedFile] = []
    @Published public var activeTransfers: [TransferSession] = []
    @Published public var incomingRequest: TransferSession? = nil
    @Published public var transferHistory: [TransferHistoryItem] = []
    @Published public var settings: AppSettings = AppSettings.load()
    @Published public var isRunning: Bool = false

    private let discoveryService = MulticastDiscoveryService()
    private let server = LocalSendHTTPServer()
    private let client = LocalSendHTTPClient()
    private let historyManager = TransferHistoryManager.shared

    // Continuation for awaiting user approval for incoming requests
    private var pendingApprovalContinuation: CheckedContinuation<Bool, Never>?
    private var activeIncomingSessions: [String: TransferSession] = [:]
    private var incomingSessionFiles: [String: [String: (item: FileTransferItem, targetURL: URL)]] = [:]

    public init() {
        self.transferHistory = historyManager.loadHistory()
        setupDiscoveryCallbacks()
        setupServerCallbacks()
    }

    /// Starts local server and network discovery.
    public func start() {
        guard !isRunning else { return }

        // Start HTTP Server
        do {
            try server.start(port: UInt16(settings.port))
        } catch {
            print("[LocalSend Engine] Could not start server on port \(settings.port): \(error)")
        }

        // Start Multicast Discovery
        discoveryService.startListening(port: UInt16(settings.multicastPort))
        broadcastAnnouncement()
        discoveryService.startPeriodicAnnounce(registerDto: currentRegisterDto, intervalSeconds: 8.0)

        isRunning = true
    }

    /// Stops server and discovery.
    public func stop() {
        guard isRunning else { return }
        discoveryService.stop()
        server.stop()
        isRunning = false
    }

    /// Re-broadcasts announcement and cleans up stale peers.
    public func refreshDiscovery() {
        let now = Date()
        discoveredDevices.removeAll { now.timeIntervalSince($0.lastSeen) > 30 }
        broadcastAnnouncement()
    }

    /// Broadcasts announcement packet.
    public func broadcastAnnouncement() {
        discoveryService.announce(registerDto: currentRegisterDto)
    }

    private var currentRegisterDto: RegisterDto {
        RegisterDto(
            alias: settings.alias,
            version: "2.2",
            deviceModel: settings.deviceType.displayName,
            deviceType: settings.deviceType,
            fingerprint: FingerprintHelper.getOrCreateFingerprint(),
            port: settings.port,
            protocol: settings.protocolType,
            download: false
        )
    }

    // MARK: - Staged Files Management

    public func addStagedFiles(urls: [URL]) {
        for url in urls {
            // Avoid adding duplicates
            if !stagedFiles.contains(where: { $0.url.path == url.path }) {
                stagedFiles.append(StagedFile(url: url))
            }
        }
    }

    public func removeStagedFile(id: String) {
        stagedFiles.removeAll { $0.id == id }
    }

    public func clearStagedFiles() {
        stagedFiles.removeAll()
    }

    // MARK: - Outgoing Transfers

    public func sendStagedFiles(to device: Device) {
        guard !stagedFiles.isEmpty else { return }
        let filesToSend = stagedFiles

        let transferItems = filesToSend.map {
            FileTransferItem(id: $0.id, fileName: $0.name, size: $0.size, localURL: $0.url)
        }

        let session = TransferSession(
            remoteDevice: device,
            direction: .sending,
            status: .waitingForApproval,
            files: transferItems
        )
        activeTransfers.append(session)

        Task { [weak self] in
            guard let self = self else { return }
            do {
                // 1. Prepare upload
                let response = try await self.client.prepareUpload(
                    to: device,
                    myInfo: self.currentRegisterDto,
                    files: filesToSend
                )

                // Update session state
                if let idx = self.activeTransfers.firstIndex(where: { $0.id == session.id }) {
                    self.activeTransfers[idx].status = .inProgress
                }

                // 2. Upload accepted files
                for file in filesToSend {
                    guard let token = response.files[file.id] else {
                        // File was rejected by receiver
                        continue
                    }

                    try await self.client.uploadFile(
                        to: device,
                        sessionId: response.sessionId,
                        file: file,
                        token: token
                    ) { [weak self] transferred, total in
                        Task { @MainActor [weak self] in
                            self?.updateOutgoingProgress(sessionId: session.id, fileId: file.id, transferred: transferred)
                        }
                    }
                }

                // Transfer completed!
                self.finishOutgoingSession(sessionId: session.id, status: .completed, error: nil)

            } catch {
                self.finishOutgoingSession(sessionId: session.id, status: .failed, error: error.localizedDescription)
            }
        }
    }

    private func updateOutgoingProgress(sessionId: String, fileId: String, transferred: Int64) {
        guard let sIdx = activeTransfers.firstIndex(where: { $0.id == sessionId }) else { return }
        if let fIdx = activeTransfers[sIdx].files.firstIndex(where: { $0.id == fileId }) {
            activeTransfers[sIdx].files[fIdx].bytesTransferred = transferred
            if transferred >= activeTransfers[sIdx].files[fIdx].size {
                activeTransfers[sIdx].files[fIdx].status = .completed
            }
        }
        let total = activeTransfers[sIdx].totalSize
        let done = activeTransfers[sIdx].transferredSize
        activeTransfers[sIdx].progress = total > 0 ? Double(done) / Double(total) : 1.0
    }

    private func finishOutgoingSession(sessionId: String, status: TransferStatus, error: String?) {
        guard let sIdx = activeTransfers.firstIndex(where: { $0.id == sessionId }) else { return }
        var session = activeTransfers[sIdx]
        session.status = status
        session.endTime = Date()
        session.errorMessage = error
        activeTransfers.remove(at: sIdx)

        if settings.saveToHistory {
            let historyItem = TransferHistoryItem(
                id: session.id,
                remoteDeviceAlias: session.remoteDevice.alias,
                remoteDeviceType: session.remoteDevice.deviceType,
                direction: .sending,
                fileCount: session.files.count,
                totalSize: session.totalSize,
                status: status,
                date: Date(),
                fileNames: session.files.map(\.fileName),
                destinationPaths: []
            )
            historyManager.addHistoryItem(historyItem)
            transferHistory = historyManager.loadHistory()
        }

        if status == .completed {
            // Clear staged files that were successfully sent
            stagedFiles.removeAll()
        }
    }

    // MARK: - Incoming Transfers & Approvals

    public func acceptIncomingRequest() {
        guard let session = incomingRequest else { return }
        incomingRequest = nil
        pendingApprovalContinuation?.resume(returning: true)
        pendingApprovalContinuation = nil

        var acceptedSession = session
        acceptedSession.status = .inProgress
        activeTransfers.append(acceptedSession)
    }

    public func declineIncomingRequest() {
        incomingRequest = nil
        pendingApprovalContinuation?.resume(returning: false)
        pendingApprovalContinuation = nil
    }

    public func cancelTransfer(id: String) {
        if let idx = activeTransfers.firstIndex(where: { $0.id == id }) {
            let session = activeTransfers[idx]
            activeTransfers.remove(at: idx)
            Task {
                try? await client.cancelSession(to: session.remoteDevice, sessionId: id)
            }
        }
    }

    // MARK: - Setup Callbacks

    private func setupDiscoveryCallbacks() {
        discoveryService.onDeviceDiscovered = { [weak self] device in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let idx = self.discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                    self.discoveredDevices[idx] = device
                } else {
                    self.discoveredDevices.append(device)
                }

                // Reply over HTTP to announce ourselves back
                Task {
                    _ = try? await self.client.register(to: device, myInfo: self.currentRegisterDto)
                }
            }
        }
    }

    private func setupServerCallbacks() {
        // Register route
        server.onRegister = { [weak self] dto, remoteIP in
            guard let self = self else {
                return RegisterResponseDto(alias: "LocalSend", version: "2.2", fingerprint: "")
            }
            if Thread.isMainThread {
                return MainActor.assumeIsolated { self.handleRegisterRequest(dto: dto, remoteIP: remoteIP) }
            } else {
                return DispatchQueue.main.sync {
                    self.handleRegisterRequest(dto: dto, remoteIP: remoteIP)
                }
            }
        }

        // Info route
        server.onGetInfo = { [weak self] in
            guard let self = self else {
                return InfoResponseDto(alias: "LocalSend", version: "2.2", fingerprint: "")
            }
            if Thread.isMainThread {
                return MainActor.assumeIsolated { self.handleInfoRequest() }
            } else {
                return DispatchQueue.main.sync {
                    self.handleInfoRequest()
                }
            }
        }

        // Prepare upload route
        server.onPrepareUpload = { [weak self] dto, remoteIP in
            guard let self = self else { return (false, "", [:]) }
            return await self.handlePrepareUploadRequest(dto: dto, remoteIP: remoteIP)
        }

        // Upload chunk route
        server.onFileUploadChunk = { [weak self] sessionId, fileId, token, data, isFinal in
            guard let self = self else { return false }
            return self.handleChunkUpload(sessionId: sessionId, fileId: fileId, token: token, data: data, isFinal: isFinal)
        }

        // Cancel route
        server.onCancelSession = { [weak self] sessionId in
            Task { @MainActor [weak self] in
                self?.finishIncomingSession(sessionId: sessionId, status: .canceled)
            }
        }
    }

    private func handleRegisterRequest(dto: RegisterDto, remoteIP: String) -> RegisterResponseDto {
        let device = Device(
            alias: dto.alias,
            version: dto.version,
            deviceModel: dto.deviceModel,
            deviceType: dto.deviceType ?? .desktop,
            fingerprint: dto.fingerprint,
            ip: remoteIP,
            port: dto.port,
            protocol: dto.protocol,
            download: dto.download,
            lastSeen: Date()
        )

        if let idx = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
            discoveredDevices[idx] = device
        } else {
            discoveredDevices.append(device)
        }

        return RegisterResponseDto(
            alias: settings.alias,
            version: "2.2",
            deviceModel: settings.deviceType.displayName,
            deviceType: settings.deviceType,
            fingerprint: FingerprintHelper.getOrCreateFingerprint(),
            download: false
        )
    }

    private func handleInfoRequest() -> InfoResponseDto {
        return InfoResponseDto(
            alias: settings.alias,
            version: "2.2",
            deviceModel: settings.deviceType.displayName,
            deviceType: settings.deviceType,
            fingerprint: FingerprintHelper.getOrCreateFingerprint(),
            download: false
        )
    }

    private func handlePrepareUploadRequest(dto: PrepareUploadRequestDto, remoteIP: String) async -> (approved: Bool, sessionId: String, tokens: [String: String]) {
        let sessionId = UUID().uuidString
        var tokens: [String: String] = [:]
        var transferItems: [FileTransferItem] = []
        var fileTargets: [String: (item: FileTransferItem, targetURL: URL)] = [:]

        let destFolder = settings.destinationURL
        try? FileManager.default.createDirectory(at: destFolder, withIntermediateDirectories: true)

        for (fileId, fileDto) in dto.files {
            let token = UUID().uuidString
            tokens[fileId] = token

            var targetURL = destFolder.appendingPathComponent(fileDto.fileName)
            var counter = 1
            let baseName = (fileDto.fileName as NSString).deletingPathExtension
            let ext = (fileDto.fileName as NSString).pathExtension
            while FileManager.default.fileExists(atPath: targetURL.path) {
                let newName = ext.isEmpty ? "\(baseName) (\(counter))" : "\(baseName) (\(counter)).\(ext)"
                targetURL = destFolder.appendingPathComponent(newName)
                counter += 1
            }

            let item = FileTransferItem(
                id: fileId,
                fileName: fileDto.fileName,
                size: fileDto.size,
                token: token,
                localURL: targetURL
            )
            transferItems.append(item)
            fileTargets[fileId] = (item, targetURL)
        }

        let senderDevice = Device(
            alias: dto.info.alias,
            version: dto.info.version,
            deviceModel: dto.info.deviceModel,
            deviceType: dto.info.deviceType ?? .desktop,
            fingerprint: dto.info.fingerprint,
            ip: remoteIP,
            port: dto.info.port,
            protocol: dto.info.protocol,
            download: dto.info.download
        )

        let incomingSession = TransferSession(
            id: sessionId,
            remoteDevice: senderDevice,
            direction: .receiving,
            status: .waitingForApproval,
            files: transferItems
        )

        incomingSessionFiles[sessionId] = fileTargets
        activeIncomingSessions[sessionId] = incomingSession

        if settings.autoAccept {
            activeTransfers.append(incomingSession)
            return (true, sessionId, tokens)
        }

        let approved = await withCheckedContinuation { continuation in
            self.pendingApprovalContinuation = continuation
            self.incomingRequest = incomingSession
        }

        return (approved, sessionId, tokens)
    }

    private nonisolated func handleChunkUpload(sessionId: String, fileId: String, token: String, data: Data, isFinal: Bool) -> Bool {
        Task { @MainActor [weak self] in
            guard let self = self,
                  let sessionFiles = self.incomingSessionFiles[sessionId],
                  let fileEntry = sessionFiles[fileId],
                  fileEntry.item.token == token else {
                return
            }

            let targetURL = fileEntry.targetURL
            do {
                if !FileManager.default.fileExists(atPath: targetURL.path) {
                    try data.write(to: targetURL)
                } else {
                    let fileHandle = try FileHandle(forWritingTo: targetURL)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try fileHandle.close()
                }

                if let sIdx = self.activeTransfers.firstIndex(where: { $0.id == sessionId }),
                   let fIdx = self.activeTransfers[sIdx].files.firstIndex(where: { $0.id == fileId }) {
                    self.activeTransfers[sIdx].files[fIdx].bytesTransferred += Int64(data.count)
                    if isFinal {
                        self.activeTransfers[sIdx].files[fIdx].status = .completed
                    }

                    let total = self.activeTransfers[sIdx].totalSize
                    let done = self.activeTransfers[sIdx].transferredSize
                    self.activeTransfers[sIdx].progress = total > 0 ? Double(done) / Double(total) : 1.0

                    if self.activeTransfers[sIdx].files.allSatisfy({ $0.status == .completed }) {
                        self.activeTransfers[sIdx].status = .completed
                        self.finishIncomingSession(sessionId: sessionId, status: .completed)
                    }
                }
            } catch {
                print("[LocalSend Server] Error writing chunk: \(error)")
            }
        }
        return true
    }

    private func finishIncomingSession(sessionId: String, status: TransferStatus) {
        guard let sIdx = activeTransfers.firstIndex(where: { $0.id == sessionId }) else { return }
        var session = activeTransfers[sIdx]
        session.status = status
        session.endTime = Date()
        activeTransfers.remove(at: sIdx)

        if settings.saveToHistory {
            let filePaths = session.files.compactMap { $0.localURL?.path }
            let historyItem = TransferHistoryItem(
                id: session.id,
                remoteDeviceAlias: session.remoteDevice.alias,
                remoteDeviceType: session.remoteDevice.deviceType,
                direction: .receiving,
                fileCount: session.files.count,
                totalSize: session.totalSize,
                status: status,
                date: Date(),
                fileNames: session.files.map(\.fileName),
                destinationPaths: filePaths
            )
            historyManager.addHistoryItem(historyItem)
            transferHistory = historyManager.loadHistory()
        }

        incomingSessionFiles.removeValue(forKey: sessionId)
        activeIncomingSessions.removeValue(forKey: sessionId)
    }

    public func clearHistory() {
        historyManager.clearHistory()
        transferHistory = []
    }
}
