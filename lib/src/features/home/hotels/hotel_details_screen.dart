// hotel_details_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import 'edit_hotel_screen.dart';

class HotelDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> hotel;

  const HotelDetailsScreen({super.key, required this.hotel});

  @override
  ConsumerState<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends ConsumerState<HotelDetailsScreen> {
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
    final dio = ref.read(dioProvider);
    final String apiUrl = '${dio.options.baseUrl}/images/upload';

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.fields['hotelId'] = widget.hotel['_id'];

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
            widget.hotel['photos'] = [...?widget.hotel['photos'], ...decoded['photoUrls']];
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
    final dio = ref.read(dioProvider);
    final photos = widget.hotel['photos'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Details'),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditHotelScreen(hotel: widget.hotel),
                ),
              );
              if (result == true && context.mounted) {
                setState(() {}); // Refresh UI if hotel data is updated
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Hotel Info Card
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
                        Icon(Icons.hotel, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          widget.hotel['name'] ?? 'Unnamed Hotel',
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
                        const Icon(Icons.location_on, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Location: ${widget.hotel['location'] ?? 'N/A'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Rating: ${widget.hotel['rating'] ?? 'N/A'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Price: LKR ${widget.hotel['price'] ?? 'N/A'}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Amenities',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.hotel['amenities']?.join(', ') ?? '-',
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
                    "${dio.options.baseUrl}/hotels/image/$photoUrl",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red),
                  );
                } else {
                  final localIndex = (index - photos.length).toInt();
                  return Image.file(
                    File(_selectedFiles[localIndex].path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red),
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
