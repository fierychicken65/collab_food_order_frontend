# Collaborative Food Ordering App (Flutter Frontend) 📱🍕

A modern, responsive, real-time collaborative food delivery application built with **Flutter** and **Riverpod**. The app supports both solo dining orders and real-time multi-device group sessions with live cart synchronization, explicit item attribution, stock status protection, participant readiness toggling, and host-controlled checkout.

---

## ✨ Features & User Flows

### 1. Modern Food Ordering Experience
- **Solo Order Flow**:
  - Browse food categories (Burgers, Pizza, Sides, Drinks, Desserts).
  - Add items to personal cart, adjust quantities with real-time stock ceiling validation, and checkout immediately via an interactive bottom sheet.
- **Group Order Flow**:
  - **Start Group Session**: Creates a group order and generates a unique, human-readable 6-character Join Code (e.g. `ABC123`). The creator is automatically designated as the **Host**.
  - **Join Group Session**: Enter the 6-character code and a display name to enter the live session as a **Participant**.

### 2. Live Collaborative Cart & Explicit Attribution
- **Real-Time Synchronization**:
  - Built on WebSockets (`web_socket_channel`). When any participant adds, updates, or removes an item, the change reflects instantly across all devices.
- **Item Attribution Badges**:
  - Every line item in the group cart clearly displays who added it:
    - Items added by you: Highlighted badge `"Added by Alice (You)"`
    - Items added by others: Secondary badge `"Added by Bob"`
  - Attribution is persisted on the backend and in final order receipts.

### 3. Real-Time Stock Availability Protection
- Products feature real-time inventory tags:
  - **In Stock**: Green badge with remaining count (`"In Stock (15)"`).
  - **Low Stock**: Amber badge when 3 or fewer remain (`"Only 2 left!"`).
  - **Out of Stock**: Red badge; "Add" button is immediately disabled.
- If two users attempt to claim the last unit simultaneously, the server's PostgreSQL pessimistic locking rejects one attempt with an error message that surfaces as a floating SnackBar on the client.

### 4. Readiness Flow & Host-Only Checkout
- **Readiness Toggle**:
  - Each participant has a 1-tap toggle between `"I'm Ready!"` and `"Still Browsing"`.
  - The cart and member list show a live count: `"X of Y members ready"`.
- **Host-Only Checkout**:
  - Only the host sees the active **"Place Group Order"** checkout button.
  - The button remains disabled with helper guidance until **all members** are marked as Ready (`allReady == true`) and the cart contains at least one item.
  - Non-hosts see an informative banner: `"Waiting for Host to place order..."`.
- **Shared Order Receipt**:
  - Upon checkout, an `ORDER_PLACED` event triggers an itemized receipt dialog across all devices displaying the Order ID, total amount paid, and items grouped with attribution tags.

### 5. Network Resiliency & Offline Catchup
- **Connection Status Pill**: Displays real-time WebSocket state in the app bar (`Live`, `Syncing...`, `Offline`).
- **Offline Banner**: If connection drops, a top banner alerts the user and provides a 1-tap `"RETRY NOW"` button.
- **Full Resync**: On reconnection, the app automatically receives the full authoritative `SESSION_STATE`, restoring carts and stock levels without duplicated entries.

---

## 🏗️ Architecture & Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── api_constants.dart    # Network endpoints & IP configuration
│   │   └── app_theme.dart        # Material 3 colors, typography & theme
│   ├── network/
│   │   └── api_client.dart       # HTTP REST client with error handling
│   └── websocket/
│       └── ws_client.dart        # Auto-reconnecting WebSocket client with heartbeats
├── features/
│   ├── home/
│   │   └── presentation/         # Home screen with Solo & Group order entrypoints
│   ├── products/
│   │   ├── data/                 # ProductRepository (REST API)
│   │   ├── models/               # Product model with stock computation
│   │   ├── presentation/         # Products screen & responsive ProductCard
│   │   └── providers/            # productsProvider (AsyncNotifier)
│   ├── normal_order/
│   │   ├── presentation/         # Solo checkout bottom sheet
│   │   └── providers/            # soloCartProvider (StateNotifier)
│   └── group_order/
│       ├── data/                 # GroupRepository (REST API)
│       ├── models/               # GroupSession, Participant, CartItem, OrderSummary
│       ├── presentation/
│       │   ├── dialogs/          # CreateGroupDialog, JoinGroupDialog, GroupOrderReceiptDialog
│       │   ├── widgets/          # CollaborativeCartWidget, ParticipantsListWidget
│       │   └── group_session_screen.dart # 3-Tab Session Screen (Menu, Cart, Members)
│       └── providers/            # groupSessionProvider (StateNotifier + WS streaming)
└── main.dart                     # App entrypoint wrapped in ProviderScope
```

---

## ⚙️ Environment & Network Configuration

Network endpoints are configured in [`lib/core/constants/api_constants.dart`](lib/core/constants/api_constants.dart).

The app automatically detects the host environment:
| Environment | Base HTTP URL | WebSocket URL |
| :--- | :--- | :--- |
| **Web / Desktop** | `http://localhost:3000` | `ws://localhost:3000/ws` |
| **Android Emulator** | `http://10.0.2.2:3000` | `ws://10.0.2.2:3000/ws` |
| **Physical Device (LAN)** | `http://<YOUR_LAN_IP>:3000` | `ws://<YOUR_LAN_IP>:3000/ws` |

> **Testing on Physical Phones via Wi-Fi**:  
> If running on a physical Android or iOS device, find your computer's local Wi-Fi IP address (e.g. `192.168.1.50`) and set:
> ```dart
> // lib/core/constants/api_constants.dart
> static const String? overrideBaseUrl = 'http://192.168.1.50:3000';
> ```

---

## 🚀 Getting Started & Running

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.24+ recommended)
- [Dart SDK](https://dart.dev/) (v3.5+ included with Flutter)
- A running instance of the backend service (see `collab_food_order_backend/README.md`)

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Static Analysis & Lints
```bash
flutter analyze
```

### 4. Run the Application
- **On Chrome (Web)**:
  ```bash
  flutter run -d chrome
  ```
- **On Android Emulator**:
  ```bash
  flutter run -d emulator-5554
  ```
- **On Connected Device**:
  ```bash
  flutter run
  ```

---

## 👥 Multi-User Testing Guide

To test real-time collaboration between multiple users:
1. **Option A: Two Chrome Windows / Tabs**
   - Open two browser tabs on the Flutter web app (e.g. `http://localhost:port`).
   - In Window 1: Tap **"Start Group Order"**, enter `"Alice"`, and note the 6-character Join Code.
   - In Window 2: Tap **"Join Group Order"**, enter the code and `"Bob"`.
   - Add items to the shared cart and watch quantities, line totals, and user attribution sync instantly!
2. **Option B: Android Emulator + Chrome Window**
   - Launch one client on the Android Emulator and one client on Chrome.
   - Both connect to the local Node.js backend seamlessly.

---

## 🧪 Automated Tests

Run the full Flutter test suite:
```bash
flutter test
```

### Test Coverage (`10 / 10` passing tests):
- **`collaborative_cart_test.dart`**:
  - Parsing and price formatting for `GroupCartItem`.
  - Empty-state placeholder rendering.
  - Item attribution badges (`"Added by Alice (You)"` vs `"Added by Bob"`).
  - Quantity steppers and deletion triggers.
  - Readiness toggle interaction (`toggle_ready_button`).
  - Host checkout button disabling when participants are not ready, and enabling when all are ready.
  - `GroupOrderReceiptDialog` confirmation rendering and attribution display.
- **`group_session_test.dart`**:
  - `GroupSessionInfo` JSON parsing and session versioning.
  - `GroupSessionState` host identity and readiness calculation.
- **`solo_cart_test.dart`**:
  - Solo cart item addition, decrements, total calculations, and available stock ceiling protection.
- **`widget_test.dart`**:
  - App root smoke test and home screen navigation.

---

## 📦 Building Applications

- **Build Debug APK**:
  ```bash
  flutter build apk --debug
  ```
  Output: `build/app/outputs/flutter-apk/app-debug.apk`

- **Build Release APK**:
  ```bash
  flutter build apk --release
  ```
  Output: `build/app/outputs/flutter-apk/app-release.apk`

- **Build Web Bundle**:
  ```bash
  flutter build web
  ```
  Output: `build/web/`
