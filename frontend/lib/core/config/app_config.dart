import 'package:flutter/foundation.dart';

/// Centralized Environment and Deployment Configuration for PlayNed
class AppConfig {
  static const String _defaultLocalHttp = kIsWeb ? 'http://127.0.0.1:8000/api/v1' : 'http://10.0.2.2:8000/api/v1';
  static const String _defaultLocalWs = kIsWeb ? 'ws://127.0.0.1:8000/api/v1' : 'ws://10.0.2.2:8000/api/v1';

  static const String rawApiUrl = String.fromEnvironment('API_URL', defaultValue: '');
  static const String rawWsUrl = String.fromEnvironment('WS_URL', defaultValue: '');

  /// Base HTTP URL for REST endpoints (e.g. https://playned-backend.onrender.com/api/v1)
  static String get apiBaseUrl {
    if (rawApiUrl.isNotEmpty) {
      final clean = rawApiUrl.trim();
      if (clean.endsWith('/api/v1')) return clean;
      return clean.endsWith('/') ? '${clean}api/v1' : '$clean/api/v1';
    }
    return _defaultLocalHttp;
  }

  /// Base WebSocket URL for real-time room synchronization (e.g. wss://playned-backend.onrender.com/api/v1)
  static String get wsBaseUrl {
    if (rawWsUrl.isNotEmpty) {
      final clean = rawWsUrl.trim();
      if (clean.endsWith('/api/v1')) return clean;
      return clean.endsWith('/') ? '${clean}api/v1' : '$clean/api/v1';
    }
    if (rawApiUrl.isNotEmpty) {
      final base = apiBaseUrl;
      if (base.startsWith('https://')) {
        return base.replaceFirst('https://', 'wss://');
      } else if (base.startsWith('http://')) {
        return base.replaceFirst('http://', 'ws://');
      }
    }
    return _defaultLocalWs;
  }
}
