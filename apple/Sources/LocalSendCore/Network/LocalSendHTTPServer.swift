import Foundation
import Network

/// Lightweight embedded HTTP server using Network.framework for LocalSend protocol v2.2.
public final class LocalSendHTTPServer: @unchecked Sendable {
    private let queue = DispatchQueue(label: "org.localsend.httpserver", qos: .userInitiated)
    private var listener: NWListener?
    public private(set) var port: UInt16 = 53317
    public private(set) var isRunning = false

    // Delegates/Handlers
    public var onRegister: (@Sendable (RegisterDto, String) -> RegisterResponseDto)?
    public var onPrepareUpload: (@Sendable (PrepareUploadRequestDto, String) async -> (approved: Bool, sessionId: String, tokens: [String: String]))?
    public var onFileUploadChunk: (@Sendable (String, String, String, Data, Bool) -> Bool)?
    public var onCancelSession: (@Sendable (String) -> Void)?
    public var onGetInfo: (@Sendable () -> InfoResponseDto)?

    public init() {}

    public func start(port: UInt16 = 53317) throws {
        guard !isRunning else { return }
        self.port = port

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw NSError(domain: "LocalSendHTTPServer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid port"])
        }

        let newListener = try NWListener(using: parameters, on: nwPort)
        self.listener = newListener

        newListener.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        newListener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[LocalSend Server] HTTP listening on port \(port)")
            case .failed(let error):
                print("[LocalSend Server] Listener failed: \(error)")
            default: break
            }
        }

        newListener.start(queue: queue)
        self.isRunning = true
    }

    public func stop() {
        isRunning = false
        listener?.cancel()
        listener = nil
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        readHTTPRequest(connection: connection, accumulatedData: Data())
    }

    private func readHTTPRequest(connection: NWConnection, accumulatedData: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }

            if error != nil {
                connection.cancel()
                return
            }

            var currentData = accumulatedData
            if let chunk = content {
                currentData.append(chunk)
            }

            // Check if we have received full HTTP headers (separated by \r\n\r\n)
            if let headerEndRange = currentData.range(of: Data("\r\n\r\n".utf8)) {
                let headerData = currentData.subdata(in: 0..<headerEndRange.lowerBound)
                let bodyData = currentData.subdata(in: headerEndRange.upperBound..<currentData.count)

                if let headerString = String(data: headerData, encoding: .utf8) {
                    self.processRequest(headerString: headerString, initialBody: bodyData, connection: connection)
                    return
                }
            }

            if isComplete {
                connection.cancel()
            } else {
                self.readHTTPRequest(connection: connection, accumulatedData: currentData)
            }
        }
    }

    private func processRequest(headerString: String, initialBody: Data, connection: NWConnection) {
        let lines = headerString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }

        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }

        let method = parts[0]
        let pathWithQuery = parts[1]

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            let headerParts = line.components(separatedBy: ": ")
            if headerParts.count == 2 {
                headers[headerParts[0].lowercased()] = headerParts[1]
            }
        }

        let contentLength = Int(headers["content-length"] ?? "") ?? 0
        let remoteIP = getRemoteIP(connection: connection)

        // If body is already fully in initialBody, dispatch immediately.
        // Otherwise, read remaining bytes.
        if initialBody.count >= contentLength {
            let fullBody = initialBody.prefix(contentLength)
            dispatchRoute(method: method, pathWithQuery: pathWithQuery, body: Data(fullBody), remoteIP: remoteIP, connection: connection)
        } else {
            // Stream the remaining body
            readFullBody(connection: connection, currentBody: initialBody, expectedLength: contentLength) { [weak self] fullBody in
                self?.dispatchRoute(method: method, pathWithQuery: pathWithQuery, body: fullBody, remoteIP: remoteIP, connection: connection)
            }
        }
    }

    private func readFullBody(connection: NWConnection, currentBody: Data, expectedLength: Int, completion: @escaping (Data) -> Void) {
        var body = currentBody
        func receiveNext() {
            let remaining = expectedLength - body.count
            if remaining <= 0 {
                completion(body)
                return
            }
            connection.receive(minimumIncompleteLength: 1, maximumLength: min(remaining, 65536)) { chunk, _, isComplete, error in
                if let chunk = chunk {
                    body.append(chunk)
                }
                if body.count >= expectedLength || isComplete || error != nil {
                    completion(body)
                } else {
                    receiveNext()
                }
            }
        }
        receiveNext()
    }

    private func dispatchRoute(method: String, pathWithQuery: String, body: Data, remoteIP: String, connection: NWConnection) {
        let components = URLComponents(string: "http://localhost\(pathWithQuery)")
        let path = components?.path ?? pathWithQuery
        let queryItems = components?.queryItems ?? []

        switch (method, path) {
        case ("POST", "/api/localsend/v2/register"):
            handleRegister(body: body, remoteIP: remoteIP, connection: connection)

        case ("POST", "/api/localsend/v2/prepare-upload"):
            Task {
                await handlePrepareUpload(body: body, remoteIP: remoteIP, connection: connection)
            }

        case ("POST", "/api/localsend/v2/upload"):
            handleUpload(queryItems: queryItems, body: body, connection: connection)

        case ("POST", "/api/localsend/v2/cancel"):
            let sessionId = queryItems.first(where: { $0.name == "sessionId" })?.value ?? ""
            onCancelSession?(sessionId)
            sendResponse(connection: connection, statusCode: 200, body: "OK")

        case ("GET", "/api/localsend/v2/info"):
            if let info = onGetInfo?() {
                if let json = try? JSONEncoder().encode(info) {
                    sendJSONResponse(connection: connection, statusCode: 200, jsonData: json)
                    return
                }
            }
            sendResponse(connection: connection, statusCode: 200, body: "{}")

        default:
            sendResponse(connection: connection, statusCode: 404, body: "Not Found")
        }
    }

    private func handleRegister(body: Data, remoteIP: String, connection: NWConnection) {
        guard let dto = try? JSONDecoder().decode(RegisterDto.self, from: body) else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid register payload")
            return
        }

        if let responseDto = onRegister?(dto, remoteIP),
           let json = try? JSONEncoder().encode(responseDto) {
            sendJSONResponse(connection: connection, statusCode: 200, jsonData: json)
        } else {
            sendResponse(connection: connection, statusCode: 200, body: "{}")
        }
    }

    private func handlePrepareUpload(body: Data, remoteIP: String, connection: NWConnection) async {
        guard let dto = try? JSONDecoder().decode(PrepareUploadRequestDto.self, from: body) else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid prepare-upload payload")
            return
        }

        guard let onPrepareUpload = onPrepareUpload else {
            sendResponse(connection: connection, statusCode: 403, body: "Transfer rejected")
            return
        }

        let result = await onPrepareUpload(dto, remoteIP)
        if result.approved {
            let responseDto = PrepareUploadResponseDto(sessionId: result.sessionId, files: result.tokens)
            if let json = try? JSONEncoder().encode(responseDto) {
                sendJSONResponse(connection: connection, statusCode: 200, jsonData: json)
            } else {
                sendResponse(connection: connection, statusCode: 500, body: "Failed to encode response")
            }
        } else {
            sendResponse(connection: connection, statusCode: 403, body: "Rejected by user")
        }
    }

    private func handleUpload(queryItems: [URLQueryItem], body: Data, connection: NWConnection) {
        let sessionId = queryItems.first(where: { $0.name == "sessionId" })?.value ?? ""
        let fileId = queryItems.first(where: { $0.name == "fileId" })?.value ?? ""
        let token = queryItems.first(where: { $0.name == "token" })?.value ?? ""

        guard !sessionId.isEmpty, !fileId.isEmpty, !token.isEmpty else {
            sendResponse(connection: connection, statusCode: 400, body: "Missing upload parameters")
            return
        }

        let success = onFileUploadChunk?(sessionId, fileId, token, body, true) ?? false
        if success {
            sendResponse(connection: connection, statusCode: 200, body: "OK")
        } else {
            sendResponse(connection: connection, statusCode: 403, body: "Invalid token or session")
        }
    }

    private func getRemoteIP(connection: NWConnection) -> String {
        if case let .hostPort(host, _) = connection.endpoint {
            switch host {
            case .ipv4(let addr): return "\(addr)"
            case .ipv6(let addr): return "\(addr)"
            case .name(let name, _): return name
            @unknown default: return "127.0.0.1"
            }
        }
        return "127.0.0.1"
    }

    private func sendResponse(connection: NWConnection, statusCode: Int, body: String) {
        let bodyData = Data(body.utf8)
        let header = "HTTP/1.1 \(statusCode) \(statusReason(statusCode))\r\nContent-Type: text/plain\r\nContent-Length: \(bodyData.count)\r\nConnection: close\r\n\r\n"
        var fullData = Data(header.utf8)
        fullData.append(bodyData)
        connection.send(content: fullData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func sendJSONResponse(connection: NWConnection, statusCode: Int, jsonData: Data) {
        let header = "HTTP/1.1 \(statusCode) \(statusReason(statusCode))\r\nContent-Type: application/json\r\nContent-Length: \(jsonData.count)\r\nConnection: close\r\n\r\n"
        var fullData = Data(header.utf8)
        fullData.append(jsonData)
        connection.send(content: fullData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func statusReason(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 204: return "No Content"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 409: return "Conflict"
        case 500: return "Internal Server Error"
        default: return "Response"
        }
    }
}
