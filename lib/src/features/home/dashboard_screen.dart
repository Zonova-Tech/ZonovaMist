import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/rooms_provider.dart';
import '../../core/api/api_service.dart';
import 'room_details_screen.dart';
import 'add_room_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _updateRoomStatus(
      WidgetRef ref,
      String roomId,
      String newStatus,
      ) async {
    final dio = ref.read(dioProvider);
    await dio.patch('/rooms/$roomId', data: {'status': newStatus});
    ref.invalidate(roomsProvider); // Refresh data after update
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
              key: ValueKey(room['_id']),
              background: Container(
                color: Colors.green,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.check, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.orange,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.undo, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  // Swipe right → Book
                  await _updateRoomStatus(ref, room['_id'], 'occupied');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Room ${room['roomNumber']} booked!')),
                  );
                } else if (direction == DismissDirection.endToStart) {
                  // Swipe left → Undo booking
                  await _updateRoomStatus(ref, room['_id'], 'available');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Booking for Room ${room['roomNumber']} undone!')),
                  );
                }
                return false; // Prevent actual list item removal
              },
              child: Card(
                child: ListTile(
                  title: Text('Room ${room['roomNumber']} - ${room['type']}'),
                  subtitle: Text(
                    'Status: ${room['status']} • LKR ${room['pricePerNight']}/night',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomDetailsScreen(room: room),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),

      // Floating Button to Add Room
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRoomScreen()),
          );
          if (added == true) {
            ref.invalidate(roomsProvider); // refresh list after adding
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
