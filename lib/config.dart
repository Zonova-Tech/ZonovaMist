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
      return _renderBaseUrl;
    }

    // ✅ Always use Render for Production (release builds)
    if (isProduction) {
      return _renderBaseUrl;
    }

    // ✅ For debug builds, also use Render by default
    return _renderBaseUrl;

    /*
    // 🔹 for test locally again,
    // just uncomment this block and set your LAN IP.

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "http://192.168.1.10:3000/api"; // device on LAN
      case TargetPlatform.iOS:
        return "http://localhost:3000/api"; // iOS simulator
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return "http://localhost:3000/api"; // desktop
      default:
        return "http://localhost:3000/api";
    }
    */
  }
}
