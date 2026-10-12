import Foundation

public enum TransferDirection: String, Codable, Sendable {
    case sending
    case receiving
}

public enum TransferStatus: String, Codable, Sendable {
    case waitingForApproval
    case inProgress
    case completed
    case canceled
    case failed

    public var isTerminal: Bool {
        switch self {
        case .completed, .canceled, .failed: return true
        case .waitingForApproval, .inProgress: return false
        }
    }

    public var displayName: String {
        switch self {
        case .waitingForApproval: return "Waiting for Approval"
        case .inProgress: return "Transferring"
        case .completed: return "Completed"
        case .canceled: return "Canceled"
        case .failed: return "Failed"
        }
    }
}

public struct FileTransferItem: Identifiable, Sendable {
    public let id: String
    public let fileName: String
    public let size: Int64
    public var bytesTransferred: Int64
    public var token: String?
    public var localURL: URL?
    public var status: TransferStatus

    public init(
        id: String,
        fileName: String,
        size: Int64,
        bytesTransferred: Int64 = 0,
        token: String? = nil,
        localURL: URL? = nil,
        status: TransferStatus = .waitingForApproval
    ) {
        self.id = id
        self.fileName = fileName
        self.size = size
        self.bytesTransferred = bytesTransferred
        self.token = token
        self.localURL = localURL
        self.status = status
    }

    public var progress: Double {
        guard size > 0 else { return status == .completed ? 1.0 : 0.0 }
        return min(1.0, max(0.0, Double(bytesTransferred) / Double(size)))
    }
}

public struct TransferSession: Identifiable, Sendable {
    public let id: String
    public let remoteDevice: Device
    public let direction: TransferDirection
    public var status: TransferStatus
    public var files: [FileTransferItem]
    public var progress: Double
    public var speedBytesPerSec: Double
    public let startTime: Date
    public var endTime: Date?
    public var errorMessage: String?

    public init(
        id: String = UUID().uuidString,
        remoteDevice: Device,
        direction: TransferDirection,
        status: TransferStatus = .waitingForApproval,
        files: [FileTransferItem] = [],
        progress: Double = 0.0,
        speedBytesPerSec: Double = 0.0,
        startTime: Date = Date(),
        endTime: Date? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.remoteDevice = remoteDevice
        self.direction = direction
        self.status = status
        self.files = files
        self.progress = progress
        self.speedBytesPerSec = speedBytesPerSec
        self.startTime = startTime
        self.endTime = endTime
        self.errorMessage = errorMessage
    }

    public var totalSize: Int64 {
        files.reduce(0) { $0 + $1.size }
    }

    public var transferredSize: Int64 {
        files.reduce(0) { $0 + $1.bytesTransferred }
    }
}

public struct TransferHistoryItem: Identifiable, Codable, Sendable {
    public let id: String
    public let remoteDeviceAlias: String
    public let remoteDeviceType: DeviceType
    public let direction: TransferDirection
    public let fileCount: Int
    public let totalSize: Int64
    public let status: TransferStatus
    public let date: Date
    public let fileNames: [String]
    public let destinationPaths: [String]

    public init(
        id: String = UUID().uuidString,
        remoteDeviceAlias: String,
        remoteDeviceType: DeviceType,
        direction: TransferDirection,
        fileCount: Int,
        totalSize: Int64,
        status: TransferStatus,
        date: Date = Date(),
        fileNames: [String] = [],
        destinationPaths: [String] = []
    ) {
        self.id = id
        self.remoteDeviceAlias = remoteDeviceAlias
        self.remoteDeviceType = remoteDeviceType
        self.direction = direction
        self.fileCount = fileCount
        self.totalSize = totalSize
        self.status = status
        self.date = date
        self.fileNames = fileNames
        self.destinationPaths = destinationPaths
    }
}
