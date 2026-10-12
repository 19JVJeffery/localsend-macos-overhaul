import Foundation
import CryptoKit

/// Helper for generating and persisting the device's unique fingerprint.
public final class FingerprintHelper: Sendable {
    private static let fingerprintKey = "localsend_device_fingerprint"

    public static func getOrCreateFingerprint() -> String {
        if let existing = UserDefaults.standard.string(forKey: fingerprintKey), !existing.isEmpty {
            return existing
        }

        // Generate a 32-character random hex string
        let randomBytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
        let fingerprint = randomBytes.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(fingerprint, forKey: fingerprintKey)
        return fingerprint
    }
}
