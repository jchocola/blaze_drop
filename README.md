# BlazeDrop

**Cross-platform local file transfer app — P2P & Server modes.**

BlazeDrop enables fast, secure file sharing between nearby devices without relying on cloud services. It operates in two mutually exclusive modes:

- **P2P Mode** — device-to-device transfer over Wi-Fi Direct (Android) / MultipeerConnectivity (iOS). Both devices run BlazeDrop.
- **Server Mode** — the host runs a local HTTP server; any guest device connects via browser (QR code scan) to upload or download files — no app installation required.

---

## Features

| Capability              | Details                                                                     |
| ----------------------- | --------------------------------------------------------------------------- |
| **P2P Transfer**        | AES-256-GCM encrypted, chunked (1 MB), with real-time speed & ETA           |
| **Server Mode**         | Self-hosted HTTP server with QR code, auto-port selection                   |
| **Web Client**          | Guest-facing upload/download UI served from `assets/web_client/`            |
| **Transfer History**    | Full session log with status, file details, and timestamps                  |
| **Conflict Resolution** | Auto-renames duplicates (`file (1).ext`) — no silent overwrites             |
| **Dark Theme**          | Aggressive dark-first UI with Inter & Space Grotesk typography              |

---

## Tech Stack

| Layer                | Technology                                             |
| -------------------- | ------------------------------------------------------ |
| **Framework**        | Flutter 3.x, Dart 3.10+                                |
| **State Management** | `flutter_bloc` (Cubit/Bloc)                            |
| **DI**               | `get_it`                                               |
| **Navigation**       | `go_router`                                            |
| **Server**           | `shelf`, `shelf_router`, `shelf_multipart`             |
| **QR Code**          | `qr_flutter`                                           |
| **Storage**          | `shared_preferences`, `gal` (gallery), `path_provider` |
| **Testing**          | `bloc_test`, `mocktail`, `flutter_test`                |

---

## Architecture

BlazeDrop follows **Clean Architecture** with a three-layer structure:

```
lib/
├── core/                 # Shared infrastructure (DI, routing, theme, utils)
│   ├── di/               # get_it dependency injection
│   ├── router/           # go_router configuration
│   ├── theme/            # Material dark theme
│   ├── constants/        # App-wide constants
│   ├── history/          # Transfer history data layer
│   ├── config/           # Configuration
│   ├── utils/            # Helpers & extensions
│   └── widgets/          # Reusable UI components
├── features/             # Feature modules (independent)
│   ├── onboarding/       # Module A — permissions & intro flow
│   ├── p2p/              # Module B — Wi-Fi Direct / MultipeerConnectivity
│   ├── server/           # Module C — HTTPS server + QR code
│   ├── history/          # Transfer history tab
│   ├── settings/         # App settings
│   └── home/             # Home / mode selection
└── main.dart             # Entry point, Cubit providers
```

Each feature module contains `presentation/` (pages, widgets, Cubits), `domain/` (entities, interfaces, use cases), and `data/` (models, repositories) layers.

---

## Getting Started

### Prerequisites

- **Flutter SDK** 3.x
- **Dart SDK** ^3.10.8
- **Xcode** (iOS) / **Android SDK** (Android)

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd blaze_drop

# Install dependencies
flutter pub get

# Run on a connected device
flutter run
```

### Platform Setup

**Android** — minimum permissions declared in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"
    android:usesPermissionFlags="neverForLocation"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

**iOS** — add to `Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs local network access to discover nearby devices for file sharing.</string>
<key>NSBonjourServices</key>
<array><string>_blazedrop._tcp</string></array>
```

---

## Running Tests

```bash
# Unit & widget tests
flutter test

# With coverage
flutter test --coverage
```

---

## Security

- **HTTPS only** in Server Mode — self-signed certificates prevent MITM attacks
- **AES-256-GCM** encryption for all P2P data streams
- **Path traversal protection** — sanitised file names on all incoming uploads
- **Auto-cleanup** — temporary files are deleted 1 hour after server stop
- **No cloud** — all transfers happen on the local network; no data leaves the device

---

## Project Structure Details

| Directory               | Purpose                                        |
| ----------------------- | ---------------------------------------------- |
| `lib/core/di/`          | `get_it` service locator registration          |
| `lib/core/router/`      | `go_router` route definitions                  |
| `lib/core/theme/`       | Material `ThemeData` (dark-first)              |
| `lib/features/p2p/`     | Device discovery, handshake, chunked transfer  |
| `lib/features/server/`  | Shelf HTTP server, QR code, client management  |
| `lib/features/history/` | Transfer session persistence & display         |
| `assets/web_client/`    | Static HTML/JS bundle served to guest browsers |

---

## Roadmap

- [ ] WebRTC support for internet-based transfers
- [ ] E2E encrypted cloud relay
- [ ] Auto-sync folders between devices
- [ ] Resume failed transfers from chunk checksums

---

## License

Proprietary. All rights reserved.
