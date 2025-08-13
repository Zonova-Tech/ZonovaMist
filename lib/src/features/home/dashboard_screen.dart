import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/rooms_provider.dart';
import '../../core/api/api_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _updateRoomStatus(
      BuildContext context, WidgetRef ref, String roomId, String newStatus) async {
    final dio = ref.read(dioProvider);

    try {
      await dio.patch('/rooms/$roomId', data: {'status': newStatus});
      ref.invalidate(roomsProvider);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'occupied'
                ? '✅ Room booked successfully'
                : '↩️ Booking undone',
          ),
          backgroundColor:
          newStatus == 'occupied' ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Failed to update room status'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: roomsAsync.when(
        data: (rooms) => ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];

            return Dismissible(
              key: Key(room['_id']),
              background: Container(
                color: Colors.green,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(Icons.check, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.orange,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.undo, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  // Swipe right → Book room
                  await _updateRoomStatus(context, ref, room['_id'], 'occupied');
                } else if (direction == DismissDirection.endToStart) {
                  // Swipe left → Undo booking
                  await _updateRoomStatus(context, ref, room['_id'], 'available');
                }
                return false; // Prevent item removal
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text('Room ${room['roomNumber']} - ${room['type']}'),
                  subtitle: Text(
                    'Status: ${room['status']} • LKR ${room['pricePerNight']}/night',
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
