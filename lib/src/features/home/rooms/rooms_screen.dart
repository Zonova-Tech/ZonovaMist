import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/auth/rooms_provider.dart';
import '../../../core/api/api_service.dart';
import '../../../shared/widgets/common_image_manager.dart';
import 'add_room_screen.dart';
import 'edit_room_screen.dart';
import 'room_rate_page.dart';
import '../../../shared/widgets/app_drawer.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  Future<void> _onEdit(Map<String, dynamic> room) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditRoomScreen(room: Map<String, dynamic>.from(room))),
    );
    if (result == true && mounted) {
      ref.refresh(roomsProvider);
    }
  }

  Future<void> _onDelete(Map<String, dynamic> room) async {
    final roomId = room['_id'] as String;
    final roomNumber = room['roomNumber'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete Room $roomNumber?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dio = ref.read(dioProvider);
        final resp = await dio.delete('/rooms/$roomId');
        if ((resp.statusCode ?? 500) >= 200 && (resp.statusCode ?? 500) < 300) {
          if (mounted) {
            ref.refresh(roomsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Room deleted')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete: ${resp.statusCode}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: 'Room Rates',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoomRatePage()),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(child: Text('No rooms found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final roomId = room['_id'] as String? ?? '';
              if (roomId.isEmpty) {
                print('Warning: roomId is empty for room ${room['roomNumber']}');
              }
              return Slidable(
                key: ValueKey(roomId),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.4,
                  children: [
                    SlidableAction(
                      onPressed: (_) => _onEdit(room),
                      backgroundColor: Colors.blue.shade500,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                    SlidableAction(
                      onPressed: (_) => _onDelete(room),
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
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
                              'Room ${room['roomNumber'] ?? 'N/A'} - ${room['type'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.hotel, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('Beds: ${room['bedCount'] ?? 'N/A'}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.group, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('Max Occupancy: ${room['maxOccupancy'] ?? 'N/A'}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('Price Per Night: LKR ${room['pricePerNight'] ?? 'N/A'}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'Status: ${room['status'] ?? 'N/A'}',
                              style: TextStyle(
                                color: room['status'] == 'available' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CommonImageManager(
                          entityType: 'Room',
                          entityId: roomId,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRoomScreen()),
          );
          if (result == true) {
            ref.refresh(roomsProvider);
          }
        },
      ),
    );
  }
}

