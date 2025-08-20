import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  String baseUrl;

  if (kIsWeb) {
    // Web build → API must be accessible on localhost or deployed server
    baseUrl = 'http://192.168.1.10:5000/api';
  } else {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      // Emulator vs real device
      // ⚠️ If using real device, replace with your PC’s LAN IP
        baseUrl = 'http://10.0.2.2:5000/api'; // works on Android emulator
        // baseUrl = 'http://192.168.x.x:5000/api'; // for real device
        break;
      case TargetPlatform.iOS:
        baseUrl = 'http://localhost:5000/api';
        break;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        baseUrl = 'http://localhost:5000/api';
        break;
      default:
        baseUrl = 'http://localhost:5000/api';
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
        final token = await storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});
