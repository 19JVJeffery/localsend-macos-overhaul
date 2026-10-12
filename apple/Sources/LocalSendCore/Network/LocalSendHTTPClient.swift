import Foundation

public enum HTTPClientError: Error, LocalizedError {
    case invalidURL
    case rejectedByUser
    case blockedByAnotherSession
    case pinRequiredOrInvalid
    case cancelled
    case badServerResponse(Int)
    case missingAcceptedToken

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid destination URL"
        case .rejectedByUser: return "The recipient declined the transfer request"
        case .blockedByAnotherSession: return "The recipient is currently busy with another transfer"
        case .pinRequiredOrInvalid: return "PIN is required or invalid"
        case .cancelled: return "The transfer was cancelled"
        case .badServerResponse(let code): return "Server responded with HTTP \(code)"
        case .missingAcceptedToken: return "The recipient declined this file"
        }
    }
}

public final class LocalSendHTTPClient: Sendable {
    private let session: URLSession

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 3600 // 1 hr for large file uploads
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    /// Registers with a peer device.
    public func register(to device: Device, myInfo: RegisterDto) async throws -> RegisterResponseDto {
        guard let url = URL(string: "\(device.urlString)/api/localsend/v2/register") else {
            throw HTTPClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(myInfo)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw HTTPClientError.badServerResponse(code)
        }

        return try JSONDecoder().decode(RegisterResponseDto.self, from: data)
    }

    /// Sends a prepare-upload request to initiate a transfer session.
    public func prepareUpload(
        to device: Device,
        myInfo: RegisterDto,
        files: [StagedFile],
        pin: String? = nil
    ) async throws -> PrepareUploadResponseDto {
        var urlString = "\(device.urlString)/api/localsend/v2/prepare-upload"
        if let pin = pin, !pin.isEmpty {
            urlString += "?pin=\(pin)"
        }

        guard let url = URL(string: urlString) else {
            throw HTTPClientError.invalidURL
        }

        var fileMap: [String: FileDto] = [:]
        for file in files {
            fileMap[file.id] = file.toFileDto()
        }

        let payload = PrepareUploadRequestDto(info: myInfo, files: fileMap)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)
        request.timeoutInterval = 60 // Allow up to 60s for user to approve on recipient device

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.badServerResponse(500)
        }

        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(PrepareUploadResponseDto.self, from: data)
        case 401:
            throw HTTPClientError.pinRequiredOrInvalid
        case 403:
            throw HTTPClientError.rejectedByUser
        case 409:
            throw HTTPClientError.blockedByAnotherSession
        default:
            throw HTTPClientError.badServerResponse(httpResponse.statusCode)
        }
    }

    /// Uploads a single file stream to the peer's upload endpoint.
    public func uploadFile(
        to device: Device,
        sessionId: String,
        file: StagedFile,
        token: String,
        progressHandler: (@Sendable (Int64, Int64) -> Void)? = nil
    ) async throws {
        guard var components = URLComponents(string: "\(device.urlString)/api/localsend/v2/upload") else {
            throw HTTPClientError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "fileId", value: file.id),
            URLQueryItem(name: "token", value: token)
        ]

        guard let url = components.url else {
            throw HTTPClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("\(file.size)", forHTTPHeaderField: "Content-Length")

        // Perform streaming upload using upload task
        let (_, response) = try await session.upload(for: request, fromFile: file.url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw HTTPClientError.badServerResponse(code)
        }

        progressHandler?(file.size, file.size)
    }

    /// Cancels a session on the recipient.
    public func cancelSession(to device: Device, sessionId: String) async throws {
        guard var components = URLComponents(string: "\(device.urlString)/api/localsend/v2/cancel") else {
            return
        }
        components.queryItems = [URLQueryItem(name: "sessionId", value: sessionId)]
        guard let url = components.url else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        _ = try? await session.data(for: request)
    }
}
