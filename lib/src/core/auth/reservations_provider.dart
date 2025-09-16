import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart';
import 'package:dio/dio.dart';

final reservationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/bookings');
  final List bookings = response.data;

  // Only pending + cancelled
  return bookings
      .where((b) => b['status'] == 'pending' || b['status'] == 'cancelled')
      .cast<Map<String, dynamic>>()
      .toList();
});
