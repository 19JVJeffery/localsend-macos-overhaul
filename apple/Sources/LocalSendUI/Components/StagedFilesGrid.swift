import SwiftUI
import LocalSendCore

/// Displays files staged to be sent, with remove action.
public struct StagedFileItemView: View {
    public let file: StagedFile
    public let onRemove: () -> Void

    public init(file: StagedFile, onRemove: @escaping () -> Void) {
        self.file = file
        self.onRemove = onRemove
    }

    public var body: some View {
        HStack(spacing: LocalSendTheme.spacingMedium) {
            // File Icon
            ZStack {
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusSmall, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: iconName(for: file.fileExtension))
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
            }

            // Name and Size
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(LocalSendFormatters.formatFileSize(file.size))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .help("Remove file")
        }
        .padding(LocalSendTheme.spacingSmall)
        .background(LocalSendTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
    }

    private func iconName(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg", "png", "heic", "gif", "webp", "svg":
            return "photo"
        case "mp4", "mov", "m4v", "mkv", "avi":
            return "film"
        case "mp3", "m4a", "wav", "flac", "aac":
            return "music.note"
        case "pdf":
            return "doc.text.fill"
        case "zip", "tar", "gz", "rar", "7z":
            return "archivebox"
        case "txt", "md", "swift", "rs", "json":
            return "doc.plaintext"
        default:
            return "doc"
        }
    }
}
