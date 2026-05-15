// hotels_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_service.dart';
import 'auth_provider.dart';

final hotelsProvider = FutureProvider<List<dynamic>>((ref) async {
  ref.watch(tokenProvider);
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/hotels');
  return response.data as List<dynamic>;
});