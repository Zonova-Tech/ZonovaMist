// rooms_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/auth/rooms_provider.dart';
import '../../../core/api/api_service.dart';
import 'add_room_screen.dart';
import '../edit_room_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  // Track selected files for each room by room ID
  final Map<String, List<XFile>> _selectedFilesMap = {};
  // Track upload futures for each room
  final Map<String, Future<void>?> _uploadFuturesMap = {};

  Future<void> _pickAndSaveImages(String roomId) async {
    final picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedFilesMap[roomId] = [...?_selectedFilesMap[roomId], ...images];
        _uploadFuturesMap[roomId] = _uploadImagesToServer(roomId, images);
      });
    }
  }

  Future<void> _uploadImagesToServer(String roomId, List<XFile> images) async {
    final dio = ref.read(dioProvider);
    final String apiUrl = '${dio.options.baseUrl}/images/upload';

    final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
      ..fields['roomId'] = roomId;

    for (var image in images) {
      request.files.add(await http.MultipartFile.fromPath('photos', image.path));
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final decoded = jsonDecode(respStr);

        if (decoded['photoUrls'] != null) {
          final rooms = ref.read(roomsProvider).value ?? [];
          final roomIndex = rooms.indexWhere((r) => r['_id'] == roomId);
          if (roomIndex != -1) {
            setState(() {
              rooms[roomIndex]['photos'] = [
                ...?rooms[roomIndex]['photos'],
                ...decoded['photoUrls']
              ];
              _selectedFilesMap[roomId] = [];
            });
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photos uploaded successfully')),
          );
        }
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint('❌ Failed upload: ${response.statusCode} - $respStr');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Upload error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photos: $e')),
      );
    }
  }

  // ---------- ACTION HELPERS (use the page's context) ----------

  Future<void> _onEdit(Map<String, dynamic> room) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditRoomScreen(room: Map<String, dynamic>.from(room))),
    );
    if (result == true && mounted) {
      // refresh the provider and rebuild
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting room: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);
    final dio = ref.read(dioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        backgroundColor: Colors.blueAccent,
      ),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(child: Text('No rooms found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index] as Map<String, dynamic>;
              final roomId = room['_id'] as String;
              final photos = room['photos'] ?? [];
              final selectedFiles = _selectedFilesMap[roomId] ?? [];

              return Slidable(
                key: ValueKey(roomId),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.45,
                  children: [
                    SlidableAction(
                      onPressed: (_) => _onEdit(room), // ✅ use helper (page context)
                      backgroundColor: Colors.blue.shade500,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                    SlidableAction(
                      onPressed: (_) => _onDelete(room), // ✅ use helper (page context)
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
                            Expanded(
                              child: Text(
                                'Room ${room['roomNumber'] ?? 'N/A'} - ${room['type'] ?? 'Unknown Type'}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(Icons.stairs, size: 18, color: Colors.grey),
                            SizedBox(width: 6),
                          ],
                        ),
                        Text('Floor: ${room['floor'] ?? 'N/A'}'),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(Icons.people, size: 18, color: Colors.grey),
                            SizedBox(width: 6),
                          ],
                        ),
                        Text('Max Occupancy: ${room['maxOccupancy'] ?? 'N/A'}'),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(Icons.attach_money, size: 18, color: Colors.grey),
                            SizedBox(width: 6),
                          ],
                        ),
                        Text('Price: LKR ${room['pricePerNight'] ?? 'N/A'}'),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(Icons.check_circle, size: 18, color: Colors.grey),
                            SizedBox(width: 6),
                          ],
                        ),
                        Text(
                          'Status: ${room['status'] ?? 'N/A'}',
                          style: TextStyle(
                            color: (room['status'] == 'available') ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _pickAndSaveImages(roomId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Add Photos',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_uploadFuturesMap[roomId] != null)
                          FutureBuilder<void>(
                            future: _uploadFuturesMap[roomId],
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const LinearProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                              } else {
                                return const Text('Upload complete!', style: TextStyle(color: Colors.green));
                              }
                            },
                          ),
                        const SizedBox(height: 8),
                        photos.isEmpty && selectedFiles.isEmpty
                            ? const Text('No photos available.')
                            : SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length + selectedFiles.length,
                            itemBuilder: (context, photoIndex) {
                              if (photoIndex < photos.length) {
                                final photoUrl = photos[photoIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Image.network(
                                    "${dio.options.baseUrl}/rooms/image/$photoUrl",
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error, color: Colors.red),
                                  ),
                                );
                              } else {
                                final localIndex = (photoIndex - photos.length);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Image.file(
                                    File(selectedFiles[localIndex.toInt()].path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error, color: Colors.red),
                                  ),
                                );
                              }
                            },
                          ),
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
