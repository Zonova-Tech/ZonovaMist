import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../config.dart';
import '../auth/auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // final token = await storage.read(key: 'jwt_token');
        final token = ref.read(tokenProvider); // Read from RAM!
        print("🔑 JWT: $token");
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('➡️ Request: ${options.method} ${options.baseUrl}${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('⬅️ Response: ${response.statusCode} ${response.data}');
        handler.next(response);
      },
      onError: (DioException e, handler) {
        print('‼️ Dio error: ${e.message}');
        print('   Response: ${e.response?.statusCode} - ${e.response?.data}');
        if (e.response?.statusCode == 401 && ref.read(tokenProvider) != null) {
          ref.read(authProvider.notifier).logout();
        }
        handler.next(e);
      },
    ),
  );

  return dio;
});
