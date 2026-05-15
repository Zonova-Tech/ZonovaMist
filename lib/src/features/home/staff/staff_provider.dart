import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_service.dart';
import '../../../core/auth/auth_provider.dart';

final staffProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    ref.watch(tokenProvider);
    final dio = ref.watch(dioProvider);
    print('🔍 Fetching staff from: ${dio.options.baseUrl}/staff');

    final response = await dio.get('/staff');
    print('✅ Staff API Response: ${response.statusCode}');
    print('📊 Staff Data: ${response.data}');

    return List<Map<String, dynamic>>.from(response.data);
  } catch (e) {
    print('❌ Staff Provider Error: $e');
    if (e is DioException) {
      print('❌ DioException Details:');
      print('   - Status Code: ${e.response?.statusCode}');
      print('   - Request URL: ${e.requestOptions.uri}');
      print('   - Response Data: ${e.response?.data}');
      print('   - Error Type: ${e.type}');
    }
    rethrow;
  }
});

final staffRolesProvider = FutureProvider<List<String>>((ref) async {
  try {
    ref.watch(tokenProvider);
    final dio = ref.watch(dioProvider);
    print('🔍 Fetching roles from: ${dio.options.baseUrl}/staff/roles');

    final response = await dio.get('/staff/roles');
    print('✅ Roles API Response: ${response.statusCode}');

    return List<String>.from(response.data);
  } catch (e) {
    print('⚠️ Roles API Error (using defaults): $e');
    // Return default roles if endpoint doesn't exist yet
    return ['Admin', 'Owner', 'Manager', 'Technician', 'Reception', 'Cleaning'];
  }
});