import SwiftUI
import LocalSendCore
import LocalSendUI

public struct AdaptiveRootView: View {
    @ObservedObject var engine: LocalSendEngine
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init(engine: LocalSendEngine) {
        self.engine = engine
    }

    public var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                IOSPadSplitView(engine: engine)
            } else {
                IOSPhoneTabView(engine: engine)
            }
        }
        .sheet(item: $engine.incomingRequest) { request in
            incomingTransferSheet(request: request)
        }
    }

    private func incomingTransferSheet(request: TransferSession) -> some View {
        VStack(spacing: LocalSendTheme.spacingLarge) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
            }

            VStack(spacing: 4) {
                Text("Transfer Request")
                    .font(.title2.weight(.bold))
                Text("\(request.remoteDevice.alias) wants to send \(request.files.count) file\(request.files.count == 1 ? "" : "s") (\(LocalSendFormatters.formatFileSize(request.totalSize)))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            List(request.files) { file in
                HStack {
                    Image(systemName: "doc")
                        .foregroundColor(.secondary)
                    Text(file.fileName)
                        .font(.body)
                        .lineLimit(1)
                    Spacer()
                    Text(LocalSendFormatters.formatFileSize(file.size))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .frame(maxHeight: 200)

            HStack(spacing: LocalSendTheme.spacingMedium) {
                Button("Decline", role: .cancel) {
                    engine.declineIncomingRequest()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Accept") {
                    engine.acceptIncomingRequest()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}
