import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_service.dart';

final staffProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
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

final staffPerformanceProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, staffId) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/staff/$staffId/performance');
    return response.data as Map<String, dynamic>;
  } catch (e) {
    print('Error fetching staff performance: $e');
    // Return default empty metrics on error
    return {
      'averageRating': 0.0,
      'totalRatings': 0,
      'totalTasksCompleted': 0,
      'recentReviews': []
    };
  }
});