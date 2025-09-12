import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  String baseUrl;

  if (kIsWeb) {
    // Web must use LAN IP
    baseUrl = 'http://192.168.8.149:3000/api';
  } else {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        baseUrl = 'http://192.168.8.149:3000/api'; // Android device
        // Use 'http://192.168.1.10:3000/api' for real Android device
        break;
      case TargetPlatform.iOS:
        baseUrl = 'http://localhost:3000/api'; // iOS simulator
        break;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        baseUrl = 'http://localhost:3000/api'; // Desktop
        break;
      default:
        baseUrl = 'http://localhost:3000/api';
    }
  }

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final storage = const FlutterSecureStorage();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Read the token from secure storage
        final token = await storage.read(key: 'jwt_token');

        // Print token to console
        print("🔑 JWT for Android: $token");

        // Add token to headers if it exists
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options); // continue request
      },
    ),
  );

  return dio;
});
