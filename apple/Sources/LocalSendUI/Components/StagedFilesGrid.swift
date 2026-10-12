import SwiftUI
import LocalSendCore

/// Displays a single file staged to be sent, with category-colored icon and smooth remove action.
public struct StagedFileItemView: View {
    public let file: StagedFile
    public let onRemove: () -> Void

    @State private var isHovered = false

    public init(file: StagedFile, onRemove: @escaping () -> Void) {
        self.file = file
        self.onRemove = onRemove
    }

    public var body: some View {
        let typeColor = LocalSendTheme.fileTypeColor(for: file.fileExtension)

        HStack(spacing: LocalSendTheme.spacingMedium) {
            // File Icon with category-tinted background
            ZStack {
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusSmall, style: .continuous)
                    .fill(typeColor.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: iconName(for: file.fileExtension))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(typeColor)
            }

            // Name and Size
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 6) {
                    Text(LocalSendFormatters.formatFileSize(file.size))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))

                    Text(file.fileExtension.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(typeColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(typeColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }

            Spacer()

            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(isHovered ? .red.opacity(0.85) : .secondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .help("Remove file")
            .animation(LocalSendMotion.snappy, value: isHovered)
        }
        .padding(LocalSendTheme.spacingSmall)
        .background(LocalSendTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous)
                .stroke(isHovered ? typeColor.opacity(0.35) : LocalSendTheme.borderSubtle, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func iconName(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg", "png", "heic", "gif", "webp", "svg", "raw", "tiff":
            return "photo.fill"
        case "mp4", "mov", "m4v", "mkv", "avi", "webm":
            return "film.fill"
        case "mp3", "m4a", "wav", "flac", "aac", "ogg":
            return "music.note"
        case "pdf":
            return "doc.text.fill"
        case "zip", "tar", "gz", "rar", "7z", "dmg", "pkg":
            return "archivebox.fill"
        case "txt", "md":
            return "text.quote"
        case "swift", "rs", "py", "js", "ts", "json", "html", "css":
            return "chevron.left.forwardslash.chevron.right"
        default:
            return "doc.fill"
        }
    }
}
