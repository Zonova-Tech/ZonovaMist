import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';

final userProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/auth/profile'); // must return the logged-in user
  return Map<String, dynamic>.from(response.data);
});