import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../core/api/api_service.dart';

class CommonImageManager extends ConsumerStatefulWidget {
  final String entityType; // e.g., "booking", "room"
  final String entityId;   // MongoDB _id

  const CommonImageManager({
    super.key,
    required this.entityType,
    required this.entityId,
  });

  @override
  ConsumerState<CommonImageManager> createState() => _CommonImageManagerState();
}

class _CommonImageManagerState extends ConsumerState<CommonImageManager> {
  List<Map<String, dynamic>> _images = [];
  List<XFile> _selectedFiles = [];
  List<Uint8List> _selectedFileBytes = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entityId.isNotEmpty) _fetchImages();
  }

  Future<void> _fetchImages() async {
    if (widget.entityId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/images/${widget.entityType}/${widget.entityId}');
      if (response.statusCode == 200) {
        setState(() {
          _images = List<Map<String, dynamic>>.from(response.data);
        });
      } else {
        setState(() => _images = []);
      }
    } catch (e) {
      setState(() => _images = []);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch images: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    if (images == null || images.isEmpty) return;

    List<Uint8List> bytesList = [];
    if (kIsWeb) {
      for (var img in images) {
        bytesList.add(await img.readAsBytes());
      }
    }

    setState(() {
      _selectedFiles.addAll(images);
      if (kIsWeb) _selectedFileBytes.addAll(bytesList);
    });

    await _uploadImages();
  }

  Future<void> _uploadImages() async {
    if (widget.entityId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking must be saved first to upload images')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final dio = ref.read(dioProvider);
      FormData formData = FormData();

      for (var file in _selectedFiles) {
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          formData.files.add(
            MapEntry('photos', MultipartFile.fromBytes(bytes, filename: file.name)),
          );
        } else {
          formData.files.add(
            MapEntry('photos', await MultipartFile.fromFile(file.path, filename: file.name)),
          );
        }
      }

      formData.fields
        ..add(MapEntry('moduleId', widget.entityId))
        ..add(MapEntry('moduleType', widget.entityType));

      final response = await dio.post('/images/upload', data: formData);

      if (response.statusCode == 200) {
        setState(() {
          _selectedFiles.clear();
          _selectedFileBytes.clear();
        });
        await _fetchImages();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Images uploaded successfully')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload images: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteImage(String publicId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.delete('/images/image', data: {'public_id': publicId});
      if (response.statusCode == 200) {
        await _fetchImages();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _pickImages,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Add Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        if (_isUploading) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        _images.isEmpty && _selectedFiles.isEmpty
            ? const Text('No photos available.')
            : CarouselSlider(
          options: CarouselOptions(
            height: 200,
            enlargeCenterPage: true,
            autoPlay: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.8,
          ),
          items: [
            ..._images.map((img) => Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  img['url'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteImage(img['public_id']),
                  ),
                ),
              ],
            )),
            ..._selectedFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Stack(
                fit: StackFit.expand,
                children: [
                  kIsWeb
                      ? Image.memory(
                    _selectedFileBytes[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                  )
                      : Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                  ),
                  const Positioned(
                    bottom: 8,
                    right: 8,
                    child: Text(
                      'Pending',
                      style: TextStyle(color: Colors.white, fontSize: 12, backgroundColor: Colors.black54),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
}
