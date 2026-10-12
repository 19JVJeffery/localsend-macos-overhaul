import Foundation
import UniformTypeIdentifiers

/// Represents a local file selected by the user, staged to be sent to another device.
public struct StagedFile: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let size: Int64
    public let url: URL
    public let mimeType: String
    public let fileExtension: String

    public init(url: URL) {
        self.id = UUID().uuidString
        self.url = url
        self.name = url.lastPathComponent
        self.fileExtension = url.pathExtension.lowercased()

        var fileSize: Int64 = 0
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            fileSize = size
        }
        self.size = fileSize

        if let uti = UTType(filenameExtension: url.pathExtension),
           let mime = uti.preferredMIMEType {
            self.mimeType = mime
        } else {
            self.mimeType = "application/octet-stream"
        }
    }

    public init(id: String = UUID().uuidString, name: String, size: Int64, url: URL, mimeType: String = "application/octet-stream") {
        self.id = id
        self.name = name
        self.size = size
        self.url = url
        self.mimeType = mimeType
        self.fileExtension = (name as NSString).pathExtension.lowercased()
    }

    public func toFileDto() -> FileDto {
        return FileDto(
            id: id,
            fileName: name,
            size: size,
            fileType: mimeType,
            sha256: nil,
            preview: nil,
            metadata: nil
        )
    }

    public static func == (lhs: StagedFile, rhs: StagedFile) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
