import 'package:Zonova_Mist/src/core/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';

// Filter state provider - default to 'upcoming' and 'advance_paid' status
final bookingFilterProvider = StateProvider<String>((ref) => 'upcoming');
final bookingStatusFilterProvider = StateProvider<String?>((ref) => 'advance_paid');
final bookingSearchProvider = StateProvider<String>((ref) => '');

// Bookings provider with filtering
final bookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(tokenProvider);
  final dio = ref.watch(dioProvider);
  final filter = ref.watch(bookingFilterProvider);
  final statusFilter = ref.watch(bookingStatusFilterProvider);
  final search = ref.watch(bookingSearchProvider);

  // Build query parameters
  final queryParams = <String, dynamic>{
    'filter': filter,
  };

  // When statusFilter is null or empty, backend will automatically exclude cancelled
  // When statusFilter has a specific value, backend will show only that status
  if (statusFilter != null && statusFilter.isNotEmpty) {
    queryParams['status'] = statusFilter;
  }
  // If statusFilter is null/empty, don't add status param - backend will exclude cancelled by default

  if (search.isNotEmpty) {
    queryParams['search'] = search;
  }

  print('📊 Fetching bookings with params: $queryParams');

  final response = await dio.get('/bookings', queryParameters: queryParams);

  print('✅ Received ${(response.data as List).length} bookings');

  return List<Map<String, dynamic>>.from(response.data);
});