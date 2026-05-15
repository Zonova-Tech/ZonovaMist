import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const bool isProduction = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );

  // Fallback URL if env not loaded
  static const String _fallbackUrl = "http://localhost:3000/api";


  static String get apiBaseUrl {
    // Read from .env file, fallback to default if not set
    return dotenv.env['API_URL'] ?? _fallbackUrl;
  }

  static const String cloudinaryCloudName = 'dqi0bndrs';
}
