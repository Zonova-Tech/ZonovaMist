import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_service.dart';

// Room Model
class Room {
  final String id;
  final String roomNumber;
  final int? floor;
  final String? type;
  final int? bedCount;
  final int? maxOccupancy;
  final double? pricePerNight;
  final String? status;
  final List<String>? amenities;
  final String? unavailableReason;

  Room({
    required this.id,
    required this.roomNumber,
    this.floor,
    this.type,
    this.bedCount,
    this.maxOccupancy,
    this.pricePerNight,
    this.status,
    this.amenities,
    this.unavailableReason,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['_id'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      floor: json['floor'],
      type: json['type'],
      bedCount: json['bedCount'],
      maxOccupancy: json['maxOccupancy'],
      pricePerNight: json['pricePerNight']?.toDouble(),
      status: json['status'],
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : null,
      unavailableReason: json['unavailableReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomNumber': roomNumber,
      'floor': floor,
      'type': type,
      'bedCount': bedCount,
      'maxOccupancy': maxOccupancy,
      'pricePerNight': pricePerNight,
      'status': status,
      'amenities': amenities,
      'unavailableReason': unavailableReason,
    };
  }

  bool get isAvailable => unavailableReason == null;
}

// Room Availability Response
class RoomAvailabilityResponse {
  final DateTime checkinDate;
  final DateTime checkoutDate;
  final List<Room> available;
  final List<Room> unavailable;
  final RoomSummary summary;

  RoomAvailabilityResponse({
    required this.checkinDate,
    required this.checkoutDate,
    required this.available,
    required this.unavailable,
    required this.summary,
  });

  factory RoomAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return RoomAvailabilityResponse(
      checkinDate: DateTime.parse(json['checkinDate']),
      checkoutDate: DateTime.parse(json['checkoutDate']),
      available: (json['available'] as List)
          .map((room) => Room.fromJson(room))
          .toList(),
      unavailable: (json['unavailable'] as List)
          .map((room) => Room.fromJson(room))
          .toList(),
      summary: RoomSummary.fromJson(json['summary']),
    );
  }
}

// Room Summary
class RoomSummary {
  final int total;
  final int available;
  final int unavailable;

  RoomSummary({
    required this.total,
    required this.available,
    required this.unavailable,
  });

  factory RoomSummary.fromJson(Map<String, dynamic> json) {
    return RoomSummary(
      total: json['total'] ?? 0,
      available: json['available'] ?? 0,
      unavailable: json['unavailable'] ?? 0,
    );
  }
}

// Room Availability Parameters
class RoomAvailabilityParams {
  final DateTime checkinDate;
  final DateTime checkoutDate;
  final String? excludeBookingId;

  RoomAvailabilityParams({
    required this.checkinDate,
    required this.checkoutDate,
    this.excludeBookingId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RoomAvailabilityParams &&
              runtimeType == other.runtimeType &&
              checkinDate == other.checkinDate &&
              checkoutDate == other.checkoutDate &&
              excludeBookingId == other.excludeBookingId;

  @override
  int get hashCode =>
      checkinDate.hashCode ^ checkoutDate.hashCode ^ excludeBookingId.hashCode;
}

// PROVIDERS

/// Provider for all rooms (returns raw Map data for existing screens)
final roomsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/rooms');
    final rooms = (response.data as List).cast<Map<String, dynamic>>();

    // Sort by room number
    rooms.sort((a, b) {
      final aNum = a['roomNumber']?.toString() ?? '';
      final bNum = b['roomNumber']?.toString() ?? '';
      return aNum.compareTo(bNum);
    });

    return rooms;
  } catch (e) {
    print('❌ Error fetching rooms: $e');
    throw Exception('Failed to load rooms');
  }
});

/// Provider for all rooms as Room objects
final allRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/rooms');
    final rooms = (response.data as List)
        .map((room) => Room.fromJson(room))
        .toList();

    // Sort by room number
    rooms.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));
    return rooms;
  } catch (e) {
    print('❌ Error fetching rooms: $e');
    throw Exception('Failed to load rooms');
  }
});

/// Provider for available rooms based on dates
final availableRoomsProvider = FutureProvider.family<RoomAvailabilityResponse, RoomAvailabilityParams>(
      (ref, params) async {
    final dio = ref.watch(dioProvider);

    try {
      final queryParams = {
        'checkinDate': params.checkinDate.toIso8601String(),
        'checkoutDate': params.checkoutDate.toIso8601String(),
      };

      // Add excludeBookingId if editing existing booking
      if (params.excludeBookingId != null) {
        queryParams['excludeBookingId'] = params.excludeBookingId!;
      }

      final response = await dio.get('/rooms/available', queryParameters: queryParams);
      return RoomAvailabilityResponse.fromJson(response.data);
    } catch (e) {
      print('❌ Error fetching available rooms: $e');
      throw Exception('Failed to load available rooms');
    }
  },
);