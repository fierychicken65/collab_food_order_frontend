import 'package:flutter/foundation.dart';

class ApiConstants {
  static const int defaultPort = 3000;

  /// Returns base HTTP URL according to platform:
  /// - Android emulator: http://10.0.2.2:3000
  /// - Windows / Desktop / Web / iOS simulator: http://localhost:3000
  static String get baseUrl {
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
