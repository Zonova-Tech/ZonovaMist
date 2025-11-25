import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_service.dart';
import '../../../shared/widgets/common_image_manager.dart';
import 'edit_room_screen.dart';
import 'room_rate_page.dart';

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
                        Text('Max Occupancy: ${widget.room['maxOccupancy'] ?? 'N/A'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Price Per Night: LKR ${widget.room['pricePerNight'] ?? 'N/A'}'),
                      ],
                    ),

                    const SizedBox(height: 15),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RoomRatePage(),
                          ),
                        );
                      },
                      child: const Text("View Room Rates"),
                    ),

                    const SizedBox(height: 15),

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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
