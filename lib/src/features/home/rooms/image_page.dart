// image_page.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'dart:typed_data';

class RoomDetailsPage extends StatefulWidget {
  final String roomId;

  const RoomDetailsPage({super.key, required this.roomId});

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  List<XFile> _selectedImages = [];
  List<Uint8List> _selectedImageBytes = [];

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
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
        _selectedImages.addAll(images);
        if (kIsWeb) {
          _selectedImageBytes.addAll(imageBytes);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room Details - ${widget.roomId}'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickImages,
            child: const Text('Add Photos'),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return kIsWeb
                    ? Image.memory(
                  _selectedImageBytes[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error, color: Colors.red),
                )
                    : Image.file(
                  File(_selectedImages[index].path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error, color: Colors.red),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}