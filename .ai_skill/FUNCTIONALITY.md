# FUNCTIONALITY.md - BLAZEDROP (Cross-Platform AirDrop)

**Version:** 1.0.0 (MVP)
**Target Platforms:** iOS 14+, Android 10+ (API 29+)
**Framework:** Flutter 3.x
**Core Libraries:** `wifi_direct_plugin`, `shelf` (HTTP Server), `dio` (HTTP Client), `qr_flutter`, `pointycastle` (Encryption).

---

## 1. PROJECT OVERVIEW
BlazeDrop is a utility application for transferring files between devices in the same local network. It operates in two mutually exclusive modes:

1.  **P2P Mode (Device-to-Device):** Requires the app to be installed on both devices. Uses Wi-Fi Direct (Android) / MultipeerConnectivity (iOS) for high-speed, internet-independent transfer.
2.  **Server Mode (Host-Client):** Requires the app only on the host device. The host starts an HTTP server; other devices (even without the app) connect via a browser using a QR code or IP link to upload/download files.

---

## 2. SYSTEM ARCHITECTURE (TECHNICAL STACK)
- **State Management:** `Riverpod` or `Bloc` (choose one, implement strictly).
- **Local Storage:** `SharedPreferences` for settings; `sqflite` for transfer history.
- **Networking:**
  - P2P: Uses `wifi_direct_plugin` (abstracts Android WiFi Direct & iOS MultipeerConnectivity).
  - Server: Uses `shelf` with `shelf_router` for REST API endpoints.
  - Client (Server Mode): Uses `dio` with `dio_http2_adapter` for chunked file transfers.
- **Encryption:** Dynamically generated self-signed SSL certificates (using `certificates` package) to enable HTTPS locally, preventing MITM attacks.

> ⛔ Статус (2026-08-16): HTTPS ОТКЛЮЧЁН. Server Mode работает только по plain HTTP (`http://ip:port`). Раздел 7 «HTTPS Only» ниже — будущая спецификация, в текущей реализации не применяется.

---

## 3. MODULE A: ONBOARDING & PERMISSIONS
**Flow:**
1.  Splash Screen (2s) -> Check permissions.
2.  **Permissions Required (Mandatory):**
    - `Android`: `ACCESS_FINE_LOCATION` (required for WiFi scanning), `NEARBY_WIFI_DEVICES` (API 33+), `POST_NOTIFICATIONS`, `READ_EXTERNAL_STORAGE` (for Android 10-) / `MANAGE_EXTERNAL_STORAGE` (only for Android 11+ if accessing all files, otherwise use SAF).
    - `iOS`: `NSLocalNetworkUsageDescription` (explain peer discovery), `NSBonjourServices` (register `_blazedrop._tcp`), `NSCameraUsageDescription` (required to capture a photo from the camera; Android needs no camera permission as it uses the capture intent).
3.  **User Action:** If permissions are denied, show a custom educational screen explaining *why* they are needed, with a "Retry" button. Do not proceed to Home without mandatory permissions.

---

## 4. MODULE B: P2P MODE (APP-TO-APP)

### 4.1. Device Discovery
- **Trigger:** User taps "P2P Mode" on the Home Screen.
- **Mechanism:** App initializes `wifi_direct_plugin` and starts listening for `_blazedrop._tcp` services via mDNS/Bonjour.
- **UI Behavior:**
  - Show a **radar animation** (sweeping arc) while scanning.
  - Display discovered devices as a **Vertical List**.
  - **Device Card UI:** Avatar (generated from initials), Device Name (e.g., "Pixel 7 Pro"), OS Icon (Android/iOS/Other), Connection Strength indicator.
  - **Auto-Refresh:** Scan every 5 seconds. Remove devices that haven't responded for 10 seconds.

### 4.2. Connection Establishment (Handshake)
1.  User clicks a Device Card.
2.  Initiator sends a **Connection Request** (payload: `{ "senderName": "Device A", "action": "FILE_TRANSFER" }`).
3.  **Receiver Flow:** A Full-Screen Overlay appears with a **Glowing Orange Pulse**.
    - Options: **[ACCEPT]** (Green) / **[DECLINE]** (Red).
    - Timeout: Auto-decline after 30 seconds.
4.  Upon Acceptance, a P2P Socket is established. Both devices exchange their local IPs and ports.

### 4.3. File Selection & Sending
- **Selection:** User taps the "+" (FAB) button or the "TAP OR DRAG FILES HERE" zone. A **source sheet** opens with three options:
  - **Files** — system file picker (`file_picker`), **Multi-Selection**.
  - **Gallery** — system photo picker (`image_picker`, PHPicker / Android Photo Picker), **Multi-Selection**.
  - **Camera** — `image_picker` single shot (Android camera intent / iOS `UIImagePickerController`).
- **Queue Management:** Selected files appear as **Horizontal Chips** at the bottom. Display file size and type icon.
- **Send Trigger:** User taps the large **"BLAZE SEND"** button (Orange).
- **Transfer Protocol:**
  - Split files into **chunks** (1 MB per chunk).
  - Send metadata first (File Name, Total Size, MIME Type).
  - Stream chunks via the established P2P socket.
- **Progress UI:** Speedometer-style gauge. Shows:
  - "Upload Speed: 45 MB/s"
  - "Remaining Time: 2s"
  - Progress Bar (Cyan to Orange gradient).

### 4.4. Receiving Files
- Files are saved to the default **Downloads** folder.
- **Conflict Resolution:** If a file with the same name exists, append `_ (1)` to the new file name automatically (do not overwrite without asking).
- **Completion:** Show a Native Notification (Local Push) when the transfer is complete.

---

## 5. MODULE C: SERVER MODE (HOST-WEB)

### 5.1. Activating the Server
- **Trigger:** User taps "Server Mode" on the Home Screen.
- **Initialization:**
  - Starts a `shelf` server on a random available port (e.g., 8080, 8081).
  - Generates a self-signed SSL certificate for HTTPS (required for iOS ATS).
- **UI State:** The screen transitions to **"Server Active"** view.

### 5.2. QR Code & Connection Info
- **Display:**
  - **Center:** Large QR Code (generated using `qr_flutter`) encoding the URL: `https://[HOST_IP]:[PORT]`.
  - **Below QR:** IP Address and Port in monospace font (e.g., `192.168.1.10:8443`).
  - **Refresh Button:** Allows regenerating the QR/Port if there are conflicts.
- **Web Client Access:** The web page served is a static HTML/CSS/JS bundle embedded in the Flutter assets (`assets/web_client/index.html`).

### 5.3. Web Client Interface (For Guest Devices)
- **Layout:** Minimalist, dark background (matching the aggressive app theme).
- **Functionality:**
  1.  **Upload Area:** Drag-and-drop zone or "Choose Files" button.
  2.  **Upload Process:** Multiple files selected -> user clicks "Upload to Host".
  3.  **Download Area:** If the host has shared specific files, they appear as a list. Guest can click a file to download it directly.
- **API Endpoints (Backend):**
  - `GET /` -> Serves the HTML page.
  - `POST /upload` -> Accepts `multipart/form-data`. Saves files to the host's temp storage.
  - `GET /files` -> Returns JSON list of available shared files on the host.
  - `GET /download/{file_id}` -> Streams the file to the guest.

### 5.4. Host Management (During Server Mode)
- **Host Upload ("HOST UPLOAD // DEPLOY ASSETS"):** "PUSH FILES" opens the same **source sheet** as P2P (Files / Gallery / Camera), then publishes the staged assets into the hub so guests can download them. Records each published file in the transfer history.
- **Connected Clients:** Display a live list of connected IPs/User-Agents.
- **Incoming Files:** Show a toast notification when a guest uploads a file. Auto-save to the "BlazeDrop" folder.
- **Stop Server:** A prominent **"STOP SERVER"** button (Red/Orange) at the bottom. Pressing it terminates the server immediately and returns to the Home screen.

---

## 6. DATA MODELS

### Device Model
```dart
class PeerDevice {
  String id;           // Unique MAC or UUID from plugin
  String name;         // User-defined device name
  String ipAddress;
  String platform;     // "android", "ios", "windows"
  bool isConnected;
}

class TransferSession {
  String sessionId;    // UUID
  String peerId;
  String direction;    // "incoming" or "outgoing"
  String mode;         // "p2p" or "server"
  List<FileItem> files;
  double progress;     // 0.0 to 1.0
  String status;       // "pending", "transferring", "completed", "failed"
  DateTime timestamp;
}

class FileItem {
  String name;
  String path;        // Absolute path on device
  int size;           // In bytes
  String mimeType;
  String? thumbnail;  // Base64 for images/videos (optional)
}

7. SECURITY & ENCRYPTION (NON-NEGOTIABLE)

> ⛔ Статус (2026-08-16): требование «HTTPS Only» временно снято — hub работает по plain HTTP. Payload-encryption P2P (AES-256-GCM) в силе.

HTTPS Only: The HTTP Server (Mode 2) MUST run over HTTPS. Self-signed certificates are accepted; the app validates the checksum.
Payload Encryption (P2P): All P2P data streams must be encrypted using AES-256-GCM. The key is negotiated via a Diffie-Hellman exchange during the initial handshake (or use the plugin's native encryption if provided).
Sanitization: Sanitize all incoming file names to prevent path traversal attacks (e.g., replacing ../ with _).
Auto-Cleanup: Temp files created during Server Mode must be deleted 1 hour after the server stops.

8. EDGE CASES & ERROR HANDLING (CRITICAL FOR AGENT)

Scenario	Expected Behavior
User closes app during transfer (Background)	On Android: Use WorkManager to finish the current chunk. On iOS: Fail-safe. If transfer breaks, resume via chunk checksum (resumable uploads).
Network Switch (WiFi to Cellular)	If P2P loses WiFi Direct, pause the transfer. Show "Network unstable. Retry?" dialog. Do NOT auto-switch to cellular data to avoid data charges.
Insufficient Storage	Before starting transfer, check free space. If < 10% of file size, block the transfer and show "Free up space" error.
Server Port Conflict	If port 8080 is busy, increment to 8081, 8082 until free. Update QR code automatically.
Guest Browser Drops	If the HTTP client disconnects mid-upload, the host must delete the partial file and log an error.
iOS Background Restrictions	iOS does NOT allow full WiFi Direct background scanning. Keep the app active. If app goes to background, the discovery stops until foreground.

Android Manifest Requirements:
xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" android:usesPermissionFlags="neverForLocation"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
iOS Info.plist Requirements:
xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs local network access to discover nearby devices for file sharing.</string>
<key>NSBonjourServices</key>
<array><string>_blazedrop._tcp</string></array>
<key>NSCameraUsageDescription</key>
<string>BlazeDrop uses the camera so you can capture a photo and share it.</string>

11. TESTING CHECKLIST (ACCEPTANCE CRITERIA)

□ Scenario 1: Android -> Android P2P transfer of a 5GB video file completes successfully.
□ Scenario 2: iOS -> Android P2P transfer of 100 images completes with correct metadata.
□ Scenario 3: Host (Android) starts Server. Guest (Windows Laptop) scans QR code and uploads a PDF. Host receives notification.
□ Scenario 4: Guest connects to Server while Host changes WiFi network. Server gracefully handles socket exception and displays "Network Disconnected".
□ Scenario 5: App is killed mid-transfer. On restart, the "History" tab shows the failed transfer with a "Resume" button (if using chunked resumable logic).
12. FUTURE SCOPE (OUT OF MVP - DO NOT IMPLEMENT YET)

WebRTC Support (for transfers over the Internet).
End-to-End Encrypted (E2EE) Cloud Relay (for when devices are not on the same network).
Auto-sync folders between devices.

