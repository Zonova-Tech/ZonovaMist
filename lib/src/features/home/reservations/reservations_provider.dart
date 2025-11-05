import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart';

// Filter state provider for reservations - default to 'upcoming' and 'pending' status
final reservationFilterProvider = StateProvider<String>((ref) => 'upcoming');
final reservationStatusFilterProvider = StateProvider<String?>((ref) => 'pending');
final reservationSearchProvider = StateProvider<String>((ref) => '');

// Reservations provider with filtering
final reservationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final filter = ref.watch(reservationFilterProvider);
  final statusFilter = ref.watch(reservationStatusFilterProvider);
  final search = ref.watch(reservationSearchProvider);

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

  print('📊 Fetching reservations with params: $queryParams');

  final response = await dio.get('/bookings', queryParameters: queryParams);

  print('✅ Received ${(response.data as List).length} reservations');

  return List<Map<String, dynamic>>.from(response.data);
});