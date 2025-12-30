// hotels_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_service.dart';

final hotelsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/hotels');
  return response.data as List<dynamic>;
});