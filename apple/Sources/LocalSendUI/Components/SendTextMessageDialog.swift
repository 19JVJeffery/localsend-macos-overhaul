import SwiftUI
import LocalSendCore
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Dialog for typing or pasting text to send as a file/message to another device.
public struct SendTextMessageDialog: View {
    @Binding var isPresented: Bool
    public let onSendText: (String) -> Void

    @State private var textContent: String = ""

    public init(isPresented: Binding<Bool>, onSendText: @escaping (String) -> Void) {
        self._isPresented = isPresented
        self.onSendText = onSendText
    }

    public var body: some View {
        VStack(spacing: LocalSendTheme.spacingLarge) {
            // Header
            VStack(spacing: LocalSendTheme.spacingSmall) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.accentColor)
                }

                Text("Send Text Message")
                    .font(.title2.weight(.bold))

                Text("Share text or clipboard contents directly with a nearby device.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Text Editor
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Message Content")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Paste from Clipboard") {
                        pasteClipboard()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }

                TextEditor(text: $textContent)
                    .frame(height: 120)
                    .padding(6)
                    .background(Color.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LocalSendTheme.cornerRadiusSmall, style: .continuous)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
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

                Button("Stage Text") {
                    let trimmed = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    isPresented = false
                    onSendText(trimmed)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(LocalSendTheme.spacingLarge)
        .frame(width: 420)
    }

    private func pasteClipboard() {
        #if os(macOS)
        if let string = NSPasteboard.general.string(forType: .string) {
            textContent = string
        }
        #else
        if let string = UIPasteboard.general.string {
            textContent = string
        }
        #endif
    }
}
