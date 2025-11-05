import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';

// Filter state provider - default to 'upcoming' and 'advance_paid' status
final bookingFilterProvider = StateProvider<String>((ref) => 'upcoming');
final bookingStatusFilterProvider = StateProvider<String?>((ref) => 'advance_paid');
final bookingSearchProvider = StateProvider<String>((ref) => '');

// Bookings provider with filtering
final bookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final filter = ref.watch(bookingFilterProvider);
  final statusFilter = ref.watch(bookingStatusFilterProvider);
  final search = ref.watch(bookingSearchProvider);

  // Build query parameters
  final queryParams = <String, dynamic>{
    'filter': filter,
  };

  if (statusFilter != null && statusFilter.isNotEmpty) {
    queryParams['status'] = statusFilter;
  }

  if (search.isNotEmpty) {
    queryParams['search'] = search;
  }

  print('📊 Fetching bookings with params: $queryParams');

  final response = await dio.get('/bookings', queryParameters: queryParams);

  print('✅ Received ${(response.data as List).length} bookings');

  return List<Map<String, dynamic>>.from(response.data);
});