import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  String baseUrl;

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Desktop (Windows/Mac/Linux) - use localhost
    baseUrl = 'http://localhost:5000/api';
  } else if (Platform.isAndroid) {
    // Android device or emulator
    final isEmulator = !Platform.environment.containsKey('ANDROID_ROOT');
    if (isEmulator) {
      baseUrl = 'http://10.0.2.2:5000/api';
    } else {
      baseUrl = 'http://192.168.1.10:5000/api';
    }
  } else {
    // Fallback for other platforms (iOS, web, etc)
    baseUrl = 'http://localhost:5000/api';
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
