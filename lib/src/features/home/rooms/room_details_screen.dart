// room_details_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../edit_room_screen.dart';

class RoomDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> room;

  const RoomDetailsScreen({super.key, required this.room});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  List<XFile> _selectedFiles = [];
  Future<void>? _uploadFuture;

  Future<void> _pickAndSaveImages() async {
    final picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(images);
        _uploadFuture = _uploadImagesToServer(images);
      });
    }
  }

  Future<void> _uploadImagesToServer(List<XFile> images) async {
    const String apiUrl = 'http://10.0.2.2:3000/api/images/upload';

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.fields['roomId'] = widget.room['_id'];

    for (var image in images) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'photos',
          image.path,
        ),
      );
    }

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        debugPrint('✅ Image uploaded successfully: $respStr');
        final decoded = jsonDecode(respStr);

        if (decoded['photoUrls'] != null) {
          setState(() {
            widget.room['photos'] = [...?widget.room['photos'], ...decoded['photoUrls']];
          });
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photos uploaded successfully')),
          );
        }
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint('❌ Failed to upload image. Status: ${response.statusCode}');
        debugPrint('Response body: $respStr');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload photos: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error uploading image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.room['photos'] ?? [];

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
                setState(() {}); // Refresh UI if room data is updated
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
                          'Room ${widget.room['roomNumber'] ?? 'N/A'} - ${widget.room['type'] ?? 'Unknown Type'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.stairs, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Floor: ${widget.room['floor'] ?? 'N/A'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Max Occupancy: ${widget.room['maxOccupancy'] ?? 'N/A'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.bed, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Bed Count: ${widget.room['bedCount'] ?? 'N/A'}'),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Status: ${widget.room['status'] ?? 'N/A'}',
                          style: TextStyle(
                            color: widget.room['status'] == 'available' ? Colors.green : Colors.red,
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
            const Text(
              'Photos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickAndSaveImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            if (_uploadFuture != null)
              FutureBuilder<void>(
                future: _uploadFuture,
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
            photos.isEmpty && _selectedFiles.isEmpty
                ? const Text('No photos available.')
                : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: photos.length + _selectedFiles.length,
              itemBuilder: (context, index) {
                if (index < photos.length) {
                  final photoUrl = photos[index];
                  return Image.network(
                    "http://localhost:3000/api/rooms/image/$photoUrl",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                  );
                } else {
                  final localIndex = (index - photos.length).toInt();
                  return Image.file(
                    File(_selectedFiles[localIndex].path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}