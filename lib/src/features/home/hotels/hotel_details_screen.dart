import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      final bytesList = await Future.wait(images.map((f) => f.readAsBytes()));

      setState(() {
        _selectedFiles.addAll(images);
        _selectedFileBytes.addAll(bytesList);
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedFiles.isEmpty) return;

    final dio = ref.read(dioProvider);
    final String apiUrl = '${dio.options.baseUrl}/images/upload';

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
      ..fields['moduleId'] = widget.hotel['_id']
      ..fields['moduleType'] = 'Hotel'
      ..fields['uploadedBy'] = 'admin'
      ..fields['imageType'] = 'general'
      ..fields['api_key'] = '351448583232497';

    for (var image in _selectedFiles) {
      request.files.add(await http.MultipartFile.fromPath('photos', image.path));
    }

    setState(() {
      _uploadFuture = request.send().then((response) async {
        final respStr = await response.stream.bytesToString();
        if (response.statusCode == 200) {
          final decoded = jsonDecode(respStr);
          if (decoded['results'] != null) {
            setState(() {
              widget.hotel['photos'] = [
                ...?widget.hotel['photos'],
                ...decoded['results'].map((r) => r['url']).toList()
              ];
              _selectedFiles.clear();
              _selectedFileBytes.clear();
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photos uploaded successfully')),
              );
            }
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${response.statusCode}')),
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos = List<String>.from(widget.hotel['photos'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hotel['name'] ?? 'Hotel Details'),
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
                    Text(widget.hotel['name'] ?? 'Hotel Name',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('City: ${widget.hotel['location']?['city'] ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Star Rating: ${widget.hotel['starRating'] ?? '-'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Select Images', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            if (_selectedFiles.isNotEmpty)
              ElevatedButton(
                onPressed: _uploadImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Upload Images', style: TextStyle(color: Colors.white)),
              ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
              itemCount: photos.length + _selectedFileBytes.length,
              itemBuilder: (context, index) {
                if (index < photos.length) {
                  return Image.network(photos[index], fit: BoxFit.cover);
                } else {
                  final localIndex = index - photos.length;
                  return Image.memory(_selectedFileBytes[localIndex], fit: BoxFit.cover);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
