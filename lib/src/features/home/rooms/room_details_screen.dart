import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_service.dart';
import '../../../shared/widgets/common_image_manager.dart';
import 'edit_room_screen.dart';

class RoomDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> room;

  const RoomDetailsScreen({super.key, required this.room});

  @override
  ConsumerState<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends ConsumerState<RoomDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final roomId = widget.room['_id'] as String? ?? '';

    // Debug pricePerNight
    print('Room Price Per Night: ${widget.room['pricePerNight']}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Details'),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditRoomScreen(room: widget.room),
                ),
              );
              if (result == true && context.mounted) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room info
                    Row(
                      children: [
                        Icon(Icons.meeting_room, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Room ${widget.room['roomNumber'] ?? 'N/A'} - ${widget.room['type'] ?? 'Unknown'}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.hotel, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Beds: ${widget.room['bedCount'] ?? 'N/A'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.group, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                            'Max Occupancy: ${widget.room['maxOccupancy'] ?? 'N/A'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                            'Price Per Night: LKR ${widget.room['pricePerNight'] ?? 'N/A'}'),
                      ],
                    ),

                    // Room Rate Display View
                    RoomRateDisplay(
                      basePrice: widget.room['pricePerNight'] != null
                          ? (widget.room['pricePerNight'] as num).toDouble()
                          : 0,
                    ),

                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Status: ${widget.room['status'] ?? 'N/A'}',
                          style: TextStyle(
                            color: widget.room['status'] == 'available'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Amenities',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.room['amenities']?.join(', ') ?? '-',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CommonImageManager(
              entityType: 'Room',
              entityId: roomId,
            ),
          ],
        ),
      ),
    );
  }
}

// Room Rate Display Widget
class RoomRateDisplay extends StatefulWidget {
  final double basePrice;

  const RoomRateDisplay({super.key, required this.basePrice});

  @override
  State<RoomRateDisplay> createState() => _RoomRateDisplayState();
}

class _RoomRateDisplayState extends State<RoomRateDisplay> {
  DateTime? checkInDate;
  int nights = 1;
  int rooms = 1;
  int people = 1;

  double calculateRate() {
    double extraPersonRate = 20;
    return (widget.basePrice * nights * rooms) +
        ((people - 1) * extraPersonRate * nights * rooms);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Check-in date picker
            Row(
              children: [
                const Text('Check-in: '),
                TextButton(
                  child: Text(checkInDate != null
                      ? DateFormat('MMM dd, yyyy').format(checkInDate!)
                      : 'Select Date'),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        checkInDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),

            // Nights
            Row(
              children: [
                const Text('Nights: '),
                DropdownButton<int>(
                  value: nights,
                  items: List.generate(30, (index) => index + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (val) => setState(() => nights = val!),
                ),
              ],
            ),

            // Rooms
            Row(
              children: [
                const Text('Rooms: '),
                DropdownButton<int>(
                  value: rooms,
                  items: List.generate(10, (index) => index + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (val) => setState(() => rooms = val!),
                ),
              ],
            ),

            // People
            Row(
              children: [
                const Text('People: '),
                DropdownButton<int>(
                  value: people,
                  items: List.generate(10, (index) => index + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (val) => setState(() => people = val!),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              'Total Price: LKR ${calculateRate().toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

