import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AppConfig {
  static const bool isProduction = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );

  static const String _renderBaseUrl = "https://zonovamistapiweb.onrender.com/api";

  static String get apiBaseUrl {
    // ✅ Always use Render for Web
    if (kIsWeb) {
      return "http://localhost:5000/api";
    }

    // ✅ Always use Render for Production (release builds)
    if (isProduction) {
      return _renderBaseUrl;
    }

    // 🔹 for test locally again
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "http://192.168.1.10:5000/api"; // device on LAN
      case TargetPlatform.iOS:
        return "http://localhost:5000/api"; // iOS simulator
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return "http://localhost:5000/api"; // desktop
      default:
        return "http://localhost:5000/api";
    }
  }
}
