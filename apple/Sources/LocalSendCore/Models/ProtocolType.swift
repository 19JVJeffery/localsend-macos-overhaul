import Foundation

/// Protocol used for LocalSend HTTP communication.
public enum ProtocolType: String, Codable, Sendable {
    case http
    case https

    public var scheme: String {
        return rawValue
    }
}
