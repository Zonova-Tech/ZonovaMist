import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/rooms_provider.dart';
import 'room_details_screen.dart';
import 'add_room_screen.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Rooms")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Add Room", style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  final added = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddRoomScreen()),
                  );
                  if (added == true) {
                    ref.invalidate(roomsProvider);
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: roomsAsync.when(
              data: (rooms) {
                if (rooms.isEmpty) {
                  return const Center(child: Text("No rooms found."));
                }
                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index] as Map<String, dynamic>;
                    return ListTile(
                      title: Text("${room['roomNumber']} - ${room['type']}"),
                      subtitle: Text("Status: ${room['status']}"),
                      trailing: Text("LKR ${room['pricePerNight']}"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomDetailsScreen(room: room),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }
}
