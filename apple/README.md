# LocalSend Native Apple (macOS, iOS & iPadOS)

A high-performance, native Apple implementation of LocalSend built with **Swift, SwiftUI, and Apple's native frameworks** (`Network.framework`, `CryptoKit`, `UniformTypeIdentifiers`).

This replaces the Flutter layer for Apple platforms with a first-party desktop and mobile experience adhering to Apple's Human Interface Guidelines (HIG), while maintaining complete wire-protocol compatibility with official LocalSend clients on Android, Windows, and Linux.

---

## Architecture Overview

```
apple/
├── LocalSendApple.xcodeproj      # Xcode project with macOS and iOS/iPadOS targets
├── Package.swift                 # Swift Package defining LocalSendCore & LocalSendUI
├── project.yml                   # XcodeGen specification for reproducible project generation
├── Sources/
│   ├── LocalSendCore/            # Shared engine & protocol v2.2 networking
│   │   ├── Models/               # Device, DeviceType, FileDto, RegisterDto, TransferSession, AppSettings
│   │   ├── Network/              # MulticastDiscoveryService, LocalSendHTTPServer, LocalSendHTTPClient
│   │   ├── Security/             # FingerprintHelper, device identity
│   │   └── State/                # LocalSendEngine (central coordinator), TransferHistoryManager
│   └── LocalSendUI/              # Shared SwiftUI design tokens & components
│       ├── Theme/                # LocalSendTheme (Apple HIG system colors, typography, materials)
│       ├── Components/           # DeviceCard (AirDrop radar), StagedFilesGrid, TransferProgressBar
│       └── Formatters/           # LocalSendFormatters (file sizes, speeds, dates)
├── Tests/
│   └── LocalSendCoreTests/       # Unit tests for protocol DTOs and fallback handling
└── Apps/
    ├── LocalSendMac/             # Native macOS Application
    │   ├── App/                  # LocalSendMacApp (@main, window & menu commands)
    │   ├── Views/                # MacMainView, MacSidebarView, MacSendView, MacReceiveView, MacHistoryView, MacSettingsView, MacReceiveModal
    │   └── Resources/            # Info.plist, LocalSendMac.entitlements
    └── LocalSendIOS/             # Universal iOS & iPadOS Application
        ├── App/                  # LocalSendIOSApp (@main)
        ├── Views/                # AdaptiveRootView, IOSPadSplitView (iPad), IOSPhoneTabView (iPhone), IOSSendView, IOSReceiveView
        └── Resources/            # Info.plist
```

---

## Platform Features

### 1. macOS (`LocalSend-macOS`)
- **Native macOS Interface**: Built using `NavigationSplitView` with customizable sidebar (`Send`, `Receive`, `History`, `Settings`).
- **AirDrop-Style Radar**: Discovered devices appear as sleek cards with OS icons, IP badges, and single-click transfers.
- **Window-Wide Drag & Drop**: Drop files anywhere on the app to immediately stage them for transfer.
- **File Management**: Quick actions to "Show in Finder" and preview transferred files.
- **System Integration**: Native macOS Toolbar, menu bar keyboard shortcuts (⌘R to refresh), and Preferences window.

### 2. iPhone (`LocalSend-iOS`)
- **Touch-First Tab Navigation**: Bottom `TabView` with Send, Receive, History, and Settings.
- **Photo & Document Pickers**: Direct integration with `PhotosPicker` (via `PhotosUI`) and the iOS Files app (`fileImporter`).
- **System Share Sheet**: Share received files directly into other iOS applications.
- **Interactive Approval**: Bottom sheet modal for incoming transfer requests.

### 3. iPadOS (`LocalSend-iOS` on iPad)
- **Adaptive Split Layout**: Automatically switches to multi-column `NavigationSplitView` on regular width screens.
- **Multitasking Support**: Full support for iPad Split View, Slide Over, and Stage Manager.
- **Drag & Drop**: Native iPad drag & drop to stage files from Files or Photos apps side-by-side.

---

## Protocol & Compatibility

Fully implements the official **LocalSend Protocol v2.2**:
- **Discovery**: UDP Multicast group `224.0.0.167:53317` + subnet broadcast fallback.
- **Endpoints**:
  - `POST /api/localsend/v2/register`
  - `POST /api/localsend/v2/prepare-upload`
  - `POST /api/localsend/v2/upload?sessionId=...&fileId=...&token=...`
  - `POST /api/localsend/v2/cancel?sessionId=...`
  - `GET /api/localsend/v2/info`
- **Zero Third-Party Networking Dependencies**: Uses Apple's modern `Network.framework` (`NWListener`, `NWConnection`) and `URLSession` for optimal battery life and performance.

---

## Building and Running

### In Xcode
1. Open `apple/LocalSendApple.xcodeproj` in Xcode.
2. Select the desired scheme from the top bar:
   - `LocalSend-macOS` for the native Mac app.
   - `LocalSend-iOS` for iPhone or iPad (Simulator or physical device).
3. Press **⌘R** to build and run.

### From Command Line
Run unit tests:
```bash
cd apple
swift test
```

Build macOS target:
```bash
cd apple
xcodebuild -project LocalSendApple.xcodeproj -scheme LocalSend-macOS -destination 'platform=macOS' build
```

Build iOS target:
```bash
cd apple
xcodebuild -project LocalSendApple.xcodeproj -scheme LocalSend-iOS -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

Regenerate Xcode project (if project.yml is modified):
```bash
cd apple
xcodegen generate
```
