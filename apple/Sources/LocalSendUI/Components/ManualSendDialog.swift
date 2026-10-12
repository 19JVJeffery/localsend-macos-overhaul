import SwiftUI
import LocalSendCore

/// Dialog for manually entering an IP address and port to send files across subnets.
public struct ManualSendDialog: View {
    @Binding var isPresented: Bool
    public let onSend: (String, Int) -> Void

    @State private var ipAddress: String = ""
    @State private var portString: String = "53317"
    @State private var errorMessage: String? = nil

    public init(isPresented: Binding<Bool>, onSend: @escaping (String, Int) -> Void) {
        self._isPresented = isPresented
        self.onSend = onSend
    }

    public var body: some View {
        VStack(spacing: LocalSendTheme.spacingLarge) {
            // Header
            VStack(spacing: LocalSendTheme.spacingSmall) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: "network")
                        .font(.system(size: 26))
                        .foregroundColor(.accentColor)
                }

                Text("Send to IP Address")
                    .font(.title2.weight(.bold))

                Text("Connect directly to a device using its local IP address.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Input Fields
            VStack(alignment: .leading, spacing: LocalSendTheme.spacingMedium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IP Address")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)

                    TextField("e.g. 192.168.1.100", text: $ipAddress)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Port")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)

                    TextField("53317", text: $portString)
                        .textFieldStyle(.roundedBorder)
                }

                if let err = errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(LocalSendTheme.spacingMedium)
            .background(LocalSendTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusMedium, style: .continuous))

            // Action Buttons
            HStack(spacing: LocalSendTheme.spacingMedium) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Connect & Send") {
                    let trimmedIP = ipAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedIP.isEmpty else {
                        errorMessage = "Please enter a valid IP address"
                        return
                    }
                    let port = Int(portString) ?? 53317
                    isPresented = false
                    onSend(trimmedIP, port)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(ipAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(LocalSendTheme.spacingLarge)
        .frame(width: 380)
    }
}
