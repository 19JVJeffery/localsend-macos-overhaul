import Foundation

/// Metadata for a transferred file.
public struct FileMetadataDto: Codable, Sendable, Equatable {
    public let modified: String?
    public let accessed: String?

    public init(modified: String? = nil, accessed: String? = nil) {
        self.modified = modified
        self.accessed = accessed
    }
}

/// DTO describing a file in LocalSend protocol v2.2.
public struct FileDto: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let fileName: String
    public let size: Int64
    public let fileType: String
    public let sha256: String?
    public let preview: String?
    public let metadata: FileMetadataDto?

    public init(
        id: String,
        fileName: String,
        size: Int64,
        fileType: String = "application/octet-stream",
        sha256: String? = nil,
        preview: String? = nil,
        metadata: FileMetadataDto? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.size = size
        self.fileType = fileType
        self.sha256 = sha256
        self.preview = preview
        self.metadata = metadata
    }
}
