import 'package:flutter/foundation.dart';

class ApiConstants {
  static const int defaultPort = 3000;

  /// Optional production backend URL override (e.g. 'https://collab-food-backend.onrender.com').
  /// Can be set directly here or passed at build time via:
  /// `flutter build apk --dart-define=BACKEND_URL=https://...`
  static const String _envUrl = String.fromEnvironment('BACKEND_URL');
  static const String overrideBaseUrl = 'https://collab-food-order-backend.onrender.com';

  /// Returns base HTTP URL:
  /// - Priority 1: `--dart-define=BACKEND_URL=...` (if passed at build time)
  /// - Priority 2: `overrideBaseUrl` (if set manually)
  /// - Priority 3: Android Emulator (`10.0.2.2:3000`)
  /// - Priority 4: Fallback to localhost:3000
  static String get baseUrl {
    if (_envUrl.isNotEmpty) {
      return _envUrl;
    }
    if (overrideBaseUrl.isNotEmpty) {
      return overrideBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:$defaultPort';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:$defaultPort';
      default:
        return 'http://localhost:$defaultPort';
    }
  }

  /// Returns base WebSocket URL
  static String get wsUrl {
    final http = baseUrl;
    if (http.startsWith('https://')) {
      return '${http.replaceFirst('https://', 'wss://')}/ws';
    }
    return '${http.replaceFirst('http://', 'ws://')}/ws';
  }

  // Endpoints
  static const String products = '/api/products';
  static const String groups = '/api/groups';
  static const String joinGroup = '/api/groups/join';
  static const String soloOrder = '/api/orders/solo';
}
