import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_service.dart';

class ProfilePictureUploader extends ConsumerStatefulWidget {
  final String entityType; // "Staff"
  final String entityId;   // Staff MongoDB _id
  final String? currentImageUrl; // Current profile picture URL
  final Function(String?)? onImageUpdated; // Callback when image changes
  final double size; // Avatar size

  const ProfilePictureUploader({
    super.key,
    required this.entityType,
    required this.entityId,
    this.currentImageUrl,
    this.onImageUpdated,
    this.size = 100,
  });

  @override
  ConsumerState<ProfilePictureUploader> createState() => _ProfilePictureUploaderState();
}

class _ProfilePictureUploaderState extends ConsumerState<ProfilePictureUploader> {
  String? _profileImageUrl;
  bool _isUploading = false;
  XFile? _selectedFile;
  Uint8List? _selectedFileBytes;

  @override
  void initState() {
    super.initState();
    _profileImageUrl = widget.currentImageUrl;
    if (widget.entityId.isNotEmpty) _fetchProfilePicture();
  }

  Future<void> _fetchProfilePicture() async {
    if (widget.entityId.isEmpty) return;

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/images/${widget.entityType}DP/${widget.entityId}');

      if (response.statusCode == 200) {
        final images = List<Map<String, dynamic>>.from(response.data);
        if (images.isNotEmpty) {
          setState(() {
            _profileImageUrl = images.first['url'];
          });
          widget.onImageUpdated?.call(_profileImageUrl);
        }
      }
    } catch (e) {
      print('Failed to fetch profile picture: $e');
      // Keep existing URL if fetch fails
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedFile = image;
      _isUploading = true;
    });

    // Load bytes for preview
    if (kIsWeb) {
      _selectedFileBytes = await image.readAsBytes();
    }

    await _uploadImage();
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedFile = image;
      _isUploading = true;
    });

    if (kIsWeb) {
      _selectedFileBytes = await image.readAsBytes();
    }

    await _uploadImage();
  }

  Future<void> _uploadImage() async {
    if (widget.entityId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff member must be saved first')),
        );
      }
      setState(() => _isUploading = false);
      return;
    }

    if (_selectedFile == null) {
      setState(() => _isUploading = false);
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      FormData formData = FormData();

      if (kIsWeb) {
        final bytes = await _selectedFile!.readAsBytes();
        formData.files.add(
          MapEntry('photos', MultipartFile.fromBytes(
            bytes,
            filename: _selectedFile!.name,
          )),
        );
      } else {
        formData.files.add(
          MapEntry('photos', await MultipartFile.fromFile(
            _selectedFile!.path,
            filename: _selectedFile!.name,
          )),
        );
      }

      // Use special entityType "StaffDP" for profile pictures
      formData.fields
        ..add(MapEntry('moduleId', widget.entityId))
        ..add(MapEntry('moduleType', '${widget.entityType}DP'))
        ..add(MapEntry('imageType', 'profile'));

      final response = await dio.post('/images/upload', data: formData);

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        if (results.isNotEmpty && results[0]['url'] != null) {
          setState(() {
            _profileImageUrl = results[0]['url'];
            _selectedFile = null;
            _selectedFileBytes = null;
          });

          widget.onImageUpdated?.call(_profileImageUrl);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteProfilePicture() async {
    if (_profileImageUrl == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Profile Picture'),
        content: const Text('Are you sure you want to remove the profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(_, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dio = ref.read(dioProvider);

      // Get the public_id from the current profile picture
      final response = await dio.get('/images/${widget.entityType}DP/${widget.entityId}');
      if (response.statusCode == 200) {
        final images = List<Map<String, dynamic>>.from(response.data);
        if (images.isNotEmpty) {
          final publicId = images.first['public_id'];

          await dio.delete('/images/image', data: {'public_id': publicId});

          setState(() {
            _profileImageUrl = null;
          });

          widget.onImageUpdated?.call(null);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture removed')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove picture: $e')),
        );
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile Picture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
              if (_profileImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Picture'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteProfilePicture();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Avatar
        CircleAvatar(
          radius: widget.size / 2,
          backgroundColor: Colors.blue.shade100,
          backgroundImage: _profileImageUrl != null
              ? NetworkImage(_profileImageUrl!)
              : null,
          child: _profileImageUrl == null
              ? Icon(
            Icons.person,
            size: widget.size / 2,
            color: Colors.blue.shade700,
          )
              : null,
        ),

        // Upload/Edit Button
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploading ? null : _showImageOptions,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isUploading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(
                Icons.camera_alt,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
