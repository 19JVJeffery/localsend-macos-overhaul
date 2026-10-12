import Foundation

public enum LocalSendFormatters {
    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    public static func formatFileSize(_ bytes: Int64) -> String {
        return byteCountFormatter.string(fromByteCount: bytes)
    }

    public static func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    public static func formatSpeed(_ bytesPerSecond: Double) -> String {
        let formatted = formatFileSize(Int64(bytesPerSecond))
        return "\(formatted)/s"
    }
}
