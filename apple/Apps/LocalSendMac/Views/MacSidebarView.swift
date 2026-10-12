import SwiftUI
import LocalSendCore
import LocalSendUI

public enum MacNavigationItem: String, CaseIterable, Identifiable {
    case send = "Send"
    case receive = "Receive"
    case history = "History"
    case settings = "Settings"

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .send: return "arrow.up.circle.fill"
        case .receive: return "arrow.down.circle.fill"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct MacSidebarView: View {
    @ObservedObject var engine: LocalSendEngine
    @Binding public var selection: MacNavigationItem?
    public var onOpenTroubleshoot: (() -> Void)?
    public var onOpenAbout: (() -> Void)?
    public var onOpenWebShare: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var hoveredItem: MacNavigationItem?

    public init(
        engine: LocalSendEngine,
        selection: Binding<MacNavigationItem?>,
        onOpenTroubleshoot: (() -> Void)? = nil,
        onOpenAbout: (() -> Void)? = nil,
        onOpenWebShare: (() -> Void)? = nil
    ) {
        self.engine = engine
        self._selection = selection
        self.onOpenTroubleshoot = onOpenTroubleshoot
        self.onOpenAbout = onOpenAbout
        self.onOpenWebShare = onOpenWebShare
    }

    private var accentColor: Color {
        LocalSendTheme.accent(for: engine.settings.accentColorPreference, colorScheme: colorScheme)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header: LocalSend Branding & Server Status
            brandingHeader
                .padding(.horizontal, LocalSendTheme.spacingMedium)
                .padding(.top, LocalSendTheme.spacingMedium)
                .padding(.bottom, LocalSendTheme.spacingSmall)

            Divider()
                .padding(.horizontal, LocalSendTheme.spacingSmall)
                .opacity(0.5)

            // Navigation Items
            VStack(spacing: 4) {
                ForEach(MacNavigationItem.allCases) { item in
                    sidebarRow(for: item)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, LocalSendTheme.spacingSmall)

            Spacer()

            // Footer: Network Chip & Utility Shortcuts
            sidebarFooter
        }
        .frame(minWidth: 200, idealWidth: 220)
        .background(LocalSendTheme.sidebarBackground(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
    }

    private var brandingHeader: some View {
        HStack(spacing: LocalSendTheme.spacingSmall) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LocalSendTheme.accentGradient(for: engine.settings.accentColorPreference, colorScheme: colorScheme))
                    .frame(width: 32, height: 32)
                    .localSendShadow(LocalSendTheme.shadowSubtle)

                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text("LocalSend")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.primary)

                    Circle()
                        .fill(LocalSendTheme.success)
                        .frame(width: 6, height: 6)
                }

                Text(engine.settings.alias)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    private func sidebarRow(for item: MacNavigationItem) -> some View {
        let isSelected = selection == item
        let isHovered = hoveredItem == item

        return Button(action: {
            withAnimation(LocalSendMotion.snappy) {
                selection = item
            }
        }) {
            HStack(spacing: 10) {
                // Leading active indicator bar
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isSelected ? accentColor : Color.clear)
                    .frame(width: 3, height: 16)

                // Icon in soft container
                Image(systemName: item.systemImage)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? accentColor : (isHovered ? accentColor : .secondary))
                    .frame(width: 20)

                Text(item.rawValue)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : (isHovered ? .primary : .secondary))

                Spacer()

                badgeView(for: item)
            }
            .padding(.vertical, 8)
            .padding(.trailing, 8)
            .background(
                RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusSmall, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.12) : (isHovered ? accentColor.opacity(0.06) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredItem = hovering ? item : nil
        }
    }

    private var sidebarFooter: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.horizontal, LocalSendTheme.spacingSmall)
                .opacity(0.5)

            HStack(spacing: 8) {
                if let onOpenTroubleshoot = onOpenTroubleshoot {
                    Button(action: onOpenTroubleshoot) {
                        Label("Troubleshoot", systemImage: "wrench.and.screwdriver")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Diagnose connection or firewall issues")
                }

                Spacer()

                if let onOpenAbout = onOpenAbout {
                    Button(action: onOpenAbout) {
                        Label("About", systemImage: "info.circle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("About LocalSend")
                }
            }
            .padding(.horizontal, LocalSendTheme.spacingMedium)
            .padding(.bottom, LocalSendTheme.spacingSmall)
        }
    }

    @ViewBuilder
    private func badgeView(for item: MacNavigationItem) -> some View {
        switch item {
        case .send:
            if !engine.stagedFiles.isEmpty {
                Text("\(engine.stagedFiles.count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.18))
                    .foregroundColor(accentColor)
                    .clipShape(Capsule())
            }
        case .receive:
            let incoming = engine.activeTransfers.filter { $0.direction == .receiving }.count
            if incoming > 0 {
                Text("\(incoming)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(LocalSendTheme.success.opacity(0.18))
                    .foregroundColor(LocalSendTheme.success)
                    .clipShape(Capsule())
            }
        case .history:
            if !engine.transferHistory.isEmpty {
                Text("\(engine.transferHistory.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        case .settings:
            EmptyView()
        }
    }
}
