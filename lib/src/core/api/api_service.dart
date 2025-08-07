import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.100:3000/api', // Use 10.0.2.2 for Android Emulator
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // Optional: Add interceptor for logging or JWT
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'jwt_token');
      options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
    },
  ));

  return dio;
});