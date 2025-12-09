import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../core/api/api_service.dart';
import 'image_zoom_viewer.dart'; // Import the new zoom viewer

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
  CarouselSliderController? _carouselController;
  int _currentIndex = 0;
  bool _movingForward = true;

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselSliderController();
    if (widget.entityId.isNotEmpty) _fetchImages();
  }

  void _autoSlide() {
    final totalItems = _images.length + _selectedFiles.length;
    if (totalItems <= 1) return;

    if (_movingForward) {
      if (_currentIndex < totalItems - 1) {
        _currentIndex++;
        _carouselController?.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          _movingForward = false;
          _currentIndex--;
          _carouselController?.previousPage(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        });
      }
    } else {
      if (_currentIndex > 0) {
        _currentIndex--;
        _carouselController?.previousPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          _movingForward = true;
          _currentIndex++;
          _carouselController?.nextPage(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        });
      }
    }
  }

  Future<void> _fetchImages() async {
    if (widget.entityId.isEmpty) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/images/${widget.entityType}/${widget.entityId}');
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _images = List<Map<String, dynamic>>.from(response.data);
        });
      } else {
        if (!mounted) return;
        setState(() => _images = []);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _images = []);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch images: $e')),
        );
      }
    } finally {
      if (!mounted) return;
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

    if (!mounted) return;

    setState(() {
      _selectedFiles.addAll(images);
      if (kIsWeb) _selectedFileBytes.addAll(bytesList);
    });

    await _uploadImages();
  }

  Future<void> _uploadImages() async {
    if (widget.entityId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking must be saved first to upload images')),
      );
      return;
    }

    if (!mounted) return;
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

      if (!mounted) return;

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
      if (!mounted) return;
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

  void _openImageViewer(int initialIndex) {
    final imageUrls = _images.map((img) => img['url'] as String).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageZoomViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          onDelete: (url) {
            final image = _images.firstWhere((img) => img['url'] == url);
            _deleteImage(image['public_id']);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 200,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOut,
            pauseAutoPlayOnTouch: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.8,
            onPageChanged: (index, reason) {
              if (!mounted) return;
              setState(() {
                _currentIndex = index;
              });
              if (reason == CarouselPageChangedReason.timed) {
                _autoSlide();
              }
            },
          ),
          items: [
            ..._images.asMap().entries.map((entry) {
              final index = entry.key;
              final img = entry.value;
              return GestureDetector(
                onTap: () => _openImageViewer(index),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      img['url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Tap to zoom',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () => _deleteImage(img['public_id']),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade200.withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(1, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
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
