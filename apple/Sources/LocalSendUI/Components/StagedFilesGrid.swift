import SwiftUI
import LocalSendCore

/// Displays a single file staged to be sent, with category-colored icon, specular borders, and smooth remove action.
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
            // File Icon with category-tinted gradient background
            ZStack {
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusSmall, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [typeColor.opacity(0.18), typeColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusSmall, style: .continuous)
                            .stroke(typeColor.opacity(0.25), lineWidth: 1)
                    )

                Image(systemName: iconName(for: file.fileExtension))
                    .font(.system(size: 21, weight: .medium))
                    .foregroundColor(typeColor)
            }

            // Name and Size
            VStack(alignment: .leading, spacing: 3) {
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
                        .foregroundColor(.secondary.opacity(0.5))

                    Text(file.fileExtension.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(typeColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(typeColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }

            Spacer()

            // Remove Button
            Button(action: onRemove) {
                ZStack {
                    Circle()
                        .fill(isHovered ? Color.red.opacity(0.12) : Color.clear)
                        .frame(width: 28, height: 28)

                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(isHovered ? .red : .secondary.opacity(0.7))
                        .font(.system(size: 19))
                }
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
                .stroke(
                    isHovered
                        ? typeColor.opacity(0.4)
                        : LocalSendTheme.borderSubtle,
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .localSendShadow(isHovered ? LocalSendTheme.shadowMedium : LocalSendTheme.shadowSubtle)
        .animation(LocalSendMotion.snappy, value: isHovered)
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
