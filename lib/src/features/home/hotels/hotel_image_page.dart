// hotel_image_page.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';

class HotelDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> hotel;

  const HotelDetailsScreen({super.key, required this.hotel});

  @override
  ConsumerState<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends ConsumerState<HotelDetailsScreen> {
  List<XFile> _selectedFiles = [];
  List<Uint8List> _selectedFileBytes = [];
  Future<void>? _uploadFuture;

  Future<void> _pickAndSaveImages() async {
    final picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      List<Uint8List> imageBytes = [];
      if (kIsWeb) {
        for (var image in images) {
          final bytes = await image.readAsBytes();
          imageBytes.add(bytes);
        }
      }
      setState(() {
        _selectedFiles.addAll(images);
        if (kIsWeb) {
          _selectedFileBytes.addAll(imageBytes);
        }
        _uploadFuture = _uploadImagesToServer(images);
      });
    }
  }

  Future<void> _uploadImagesToServer(List<XFile> images) async {
    final dio = ref.read(dioProvider);
    final String apiUrl = '${dio.options.baseUrl}/images/upload/hotel';

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.fields['hotelId'] = widget.hotel['_id'];

    for (var image in images) {
      final bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'photos',
          bytes,
          filename: image.name,
        ),
      );
    }

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final decoded = jsonDecode(respStr);

        if (decoded['photoUrls'] != null) {
          setState(() {
            widget.hotel['photos'] = [...?widget.hotel['photos'], ...decoded['photoUrls']];
            _selectedFiles = [];
            _selectedFileBytes = [];
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
        debugPrint('Response: $respStr');
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
        title: Text('Hotel Details - ${widget.hotel['name'] ?? 'Hotel'}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hotel['name'] ?? 'Hotel Name',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('City: ${widget.hotel['location']?['city'] ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Star Rating: ${widget.hotel['starRating'] ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Price Range: LKR ${widget.hotel['priceRange'] ?? '-'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickAndSaveImages,
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
            const SizedBox(height: 16),
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
                    "${dio.options.baseUrl}/images/image/$photoUrl",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red),
                  );
                } else {
                  final localIndex = (index - photos.length).toInt();
                  return kIsWeb
                      ? Image.memory(
                    _selectedFileBytes[localIndex],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red),
                  )
                      : Image.file(
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