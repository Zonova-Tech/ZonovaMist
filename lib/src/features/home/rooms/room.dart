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