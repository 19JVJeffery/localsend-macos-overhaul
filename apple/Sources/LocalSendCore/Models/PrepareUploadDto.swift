import Foundation

/// Request body for POST /api/localsend/v2/prepare-upload
public struct PrepareUploadRequestDto: Codable, Sendable {
    public let info: RegisterDto
    public let files: [String: FileDto]

    public init(info: RegisterDto, files: [String: FileDto]) {
        self.info = info
        self.files = files
    }
}

/// Response body for POST /api/localsend/v2/prepare-upload
public struct PrepareUploadResponseDto: Codable, Sendable {
    public let sessionId: String
    public let files: [String: String]

    public init(sessionId: String, files: [String: String]) {
        self.sessionId = sessionId
        self.files = files
    }
}
