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
    request.fields['roomId'] = widget.room['_id']; // Room ID for Mongo

    for (var image in images) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'photos', // <-- field name MUST match multer config
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

        // If you want to update the local state with uploaded URLs:
        if (decoded['photoUrls'] != null) {
          setState(() {
            widget.room['photos'] =
            [...?widget.room['photos'], ...decoded['photoUrls']];
          });
        }
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint('❌ Failed to upload image. Status: ${response.statusCode}');
        debugPrint('Response body: $respStr');
      }
    } catch (e) {
      debugPrint('⚠️ Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.room['photos'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditRoomScreen(room: widget.room),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.room['roomNumber']} - ${widget.room['type']}',
                style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Floor: ${widget.room['floor']}'),
                Text('Max Occupancy: ${widget.room['maxOccupancy']}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bed Count: ${widget.room['bedCount']}'),
                Text('Price Per Night: LKR ${widget.room['pricePerNight']}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Status: '),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.room['status'] == 'available'
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.room['status'].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text('Amenities',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.room['amenities']?.join(', ') ?? '-'),

            const SizedBox(height: 16),
            const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold)),

            ElevatedButton(
              onPressed: _pickAndSaveImages,
              child: const Text('Add Photos'),
            ),
            const SizedBox(height: 8),

            if (_uploadFuture != null)
              FutureBuilder<void>(
                future: _uploadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return const Text('Upload complete!');
                  }
                },
              ),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: photos.length + _selectedFiles.length,
                itemBuilder: (context, index) {
                  if (index < photos.length) {
                    // Already uploaded images from DB
                    final photoUrl = photos[index];
                    return Image.network(
                      "http://10.0.2.2:3000$photoUrl",
                      fit: BoxFit.cover,
                    );
                  } else {
                    // Newly picked local images
                    final localIndex = (index - photos.length).toInt();
                    return Image.file(
                      File(_selectedFiles[localIndex].path),
                      fit: BoxFit.cover,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
