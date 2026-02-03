import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../core/api/api_service.dart';
import '../models/nic_data.dart';
import 'image_zoom_viewer.dart';

class CommonImageManager extends ConsumerStatefulWidget {
  final String entityType;
  final String entityId;

  /// Callback when user selects and applies NIC data
  final Function(NICData nicData)? onNICDataSelected;

  /// Optional callback for image uploads (non-NIC)
  final Function(String imageUrl, List<String> labels)? onImageUploaded;

  const CommonImageManager({
    super.key,
    required this.entityType,
    required this.entityId,
    this.onNICDataSelected,
    this.onImageUploaded,
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

  // NIC detection state - stores all detected NICs
  final List<NICDetection> _detectedNICs = [];
  bool _showNICButton = false;

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
          if (mounted) {
            _movingForward = false;
            _currentIndex--;
            _carouselController?.previousPage(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            );
          }
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
          if (mounted) {
            _movingForward = true;
            _currentIndex++;
            _carouselController?.nextPage(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
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
        SnackBar(
          content: Text('${widget.entityType} must be saved first to upload images'),
        ),
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
        final responseData = response.data;

        // Handle NIC detections - store them internally
        if (responseData['nicDetections'] != null) {
          final nicDetections = (responseData['nicDetections'] as List)
              .map((detection) => NICDetection.fromJson(detection))
              .toList();

          setState(() {
            _detectedNICs.addAll(nicDetections);
            // Show the floating button if we have valid NICs
            _showNICButton = _detectedNICs.any((nic) => nic.nicData.hasValidData);
          });

          // Show subtle notification
          if (context.mounted && nicDetections.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.badge, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${nicDetections.length} NIC${nicDetections.length > 1 ? 's' : ''} detected',
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  ],
                ),
                backgroundColor: Colors.blue.shade700,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }

        // Handle regular image uploads
        final images = responseData['images'] as List;
        for (final image in images) {
          final labels = List<String>.from(image['labels'] ?? []);
          final isNIC = image['isNICDetected'] ?? false;

          if (!isNIC && widget.onImageUploaded != null) {
            widget.onImageUploaded!(image['url'], labels);
          }
        }

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

  void _showNICSelectionDialog() {
    if (_detectedNICs.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.badge, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text('${_detectedNICs.length} NIC${_detectedNICs.length > 1 ? 's' : ''} Detected'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _detectedNICs.length == 1
              ? _buildSingleNICView(_detectedNICs.first)
              : _buildMultipleNICsView(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleNICView(NICDetection detection) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confidence score
          LinearProgressIndicator(
            value: detection.nicData.confidence,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              detection.nicData.confidence > 0.7 ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${(detection.nicData.confidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Divider(height: 24),

          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              detection.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),

          // Extracted fields
          _buildNICField('Full Name', detection.nicData.fullName,
              detection.nicData.fieldsExtracted.name),
          _buildNICField('NIC Number', detection.nicData.nicNumber,
              detection.nicData.fieldsExtracted.nic),
          _buildNICField(
            'Date of Birth',
            detection.nicData.dateOfBirth != null
                ? '${detection.nicData.dateOfBirth!.day}/${detection.nicData.dateOfBirth!.month}/${detection.nicData.dateOfBirth!.year}'
                : null,
            detection.nicData.fieldsExtracted.dob,
          ),
          _buildNICField('Address', detection.nicData.address,
              detection.nicData.fieldsExtracted.address),

          // Errors/Warnings
          if (detection.nicData.errors.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Issues:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ...detection.nicData.errors.map((error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    error.isError ? Icons.error : Icons.warning,
                    size: 14,
                    color: error.isError ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error.message,
                      style: TextStyle(
                        fontSize: 11,
                        color: error.isError ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],

          const SizedBox(height: 16),

          // Use button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onNICDataSelected?.call(detection.nicData);
                Navigator.pop(context);
                setState(() {
                  _showNICButton = false; // Hide button after use
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('NIC data applied'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Use This Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleNICsView() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _detectedNICs.length,
      itemBuilder: (context, index) {
        final detection = _detectedNICs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              _showDetailedNICDialog(detection);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image thumbnail
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          detection.imageUrl,
                          height: 60,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detection.nicData.fullName ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              detection.nicData.nicNumber ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  detection.nicData.hasValidData
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  size: 14,
                                  color: detection.nicData.hasValidData
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(detection.nicData.confidence * 100).toStringAsFixed(0)}% confidence',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetailedNICDialog(NICDetection detection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('NIC Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: _buildSingleNICView(detection),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNICField(String label, String? value, bool extracted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                extracted ? Icons.check_circle : Icons.help_outline,
                size: 14,
                color: extracted ? Colors.green : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'Not extracted',
            style: TextStyle(
              fontSize: 14,
              color: value != null ? Colors.black87 : Colors.grey,
              fontStyle: value != null ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
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

    return Stack(
      children: [
        Column(
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
              child: const Text(
                'Add Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),

            if (_isUploading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uploading and analyzing images...',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ],

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
                  final isNIC = img['isNICDetected'] ?? false;

                  return GestureDetector(
                    onTap: () => _openImageViewer(index),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          img['url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, color: Colors.red),
                        ),

                        // NIC badge
                        if (isNIC)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.badge, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'NIC',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Zoom indicator
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

                        // Delete button
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
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error, color: Colors.red),
                      )
                          : Image.file(
                        File(file.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error, color: Colors.red),
                      ),
                      const Positioned(
                        bottom: 8,
                        right: 8,
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),

        // Floating "Apply NIC Data" button
        if (_showNICButton)
          Positioned(
            right: 0,
            top: 8,
            child: FloatingActionButton.extended(
              onPressed: _showNICSelectionDialog,
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.badge),
              label: Text('Apply NIC Data${_detectedNICs.length > 1 ? ' (${_detectedNICs.length})' : ''}'),
              // No heroTag needed - parent may already be in a Hero widget
            ),
          ),
      ],
    );
  }
}