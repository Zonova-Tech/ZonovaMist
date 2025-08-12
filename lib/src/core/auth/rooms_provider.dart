import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart';

final roomsProvider = FutureProvider.family<List<dynamic>, String?>((ref, status) async {
  final dio = ref.read(dioProvider);

  try {
    final response = await dio.get(
      '/rooms',
      queryParameters: status != null && status != 'All'
          ? { 'status': status.toLowerCase() }
          : {},
    );
    return response.data;
  } on DioException catch (e) {
    throw Exception(e.response?.data['message'] ?? 'Failed to fetch rooms');
  }
});
