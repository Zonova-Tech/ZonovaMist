import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AppConfig {
  /// Set to true to force production URLs (Render)
  /// Set to false to use localhost/dev URLs
  static const bool useProduction = bool.fromEnvironment('USE_PRODUCTION', defaultValue: false);

  static const String _renderBaseUrl = "https://zonova-mist.onrender.com/api";

  /// Localhost URLs for different platforms
  static const String _androidEmulatorUrl = "http://10.0.2.2:3000/api";
  static const String _iosSimulatorUrl = "http://localhost:3000/api";
  static const String _desktopUrl = "http://localhost:3000/api";

  /// Returns the API base URL based on platform & environment
  static String get apiBaseUrl {
    if (useProduction) {
      // Always use Render in production
      return _renderBaseUrl;
    }

    // Local development URLs
    if (kIsWeb) {
      return "http://localhost:3000/api"; // CORS must be allowed in backend
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidEmulatorUrl;
      case TargetPlatform.iOS:
        return _iosSimulatorUrl;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return _desktopUrl;
      default:
        return _desktopUrl;
    }
  }
}
