import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

/// Edit Expense Page - Allows users to modify existing expense entries
/// Users can update expense details and manage attached images
/// Supports adding new images and deleting existing images
class EditExpensePage extends StatefulWidget {
  // Existing expense data to be edited
  final Map<String, dynamic> expense;

  const EditExpensePage({super.key, required this.expense});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Selected expense category
  String? _category;

  // Text controllers for form fields
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // Selected date for the expense
  DateTime _date = DateTime.now();

  // List of newly picked images to upload
  final List<XFile> _newPicked = [];

  // List of existing images from the server
  late List<Map<String, dynamic>> _existing;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Load category from expense data
    _category = widget.expense['category']?.toString();

    // Load title from expense data
    _titleCtrl.text = widget.expense['title']?.toString() ?? '';

    // Parse and load date from expense data
    final dateStr = widget.expense['date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      _date = DateTime.tryParse(dateStr) ?? DateTime.now();
    }

    // Load description/note from expense data
    _noteCtrl.text = widget.expense['description']?.toString() ?? '';

    // Parse and load existing images from expense data
    final images = widget.expense['images'];
    if (images != null && images is List && images.isNotEmpty) {
      _existing = images.map((img) {
        // Handle image data as Map
        if (img is Map) {
          return {
            'url': img['url']?.toString() ?? '',
            'cloudinary_id': img['cloudinary_id']?.toString() ?? '',
            'filename': img['filename']?.toString() ?? '',
            'fileSize': img['fileSize'] ?? 0,
            'mimeType': img['mimeType']?.toString() ?? 'image/jpeg',
          };
        }
        // Handle image data as String (URL only)
        if (img is String) {
          return {
            'url': img,
            'cloudinary_id': '',
            'filename': '',
            'fileSize': 0,
            'mimeType': 'image/jpeg',
          };
        }
        // Handle invalid image data
        return {
          'url': '',
          'cloudinary_id': '',
          'filename': '',
          'fileSize': 0,
          'mimeType': 'image/jpeg',
        };
      }).where((m) => (m['url'] as String).isNotEmpty).toList();
    } else {
      _existing = [];
    }
  }

  @override
  void dispose() {
    // Clean up controllers when widget is disposed
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// Pick new images to add to the expense
  /// Supports multi-image selection from gallery
  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() => _newPicked.addAll(images));
    }
  }

  /// Show date picker dialog and update selected date
  /// Date range: 2000 to today
  Future<void> _selectDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  /// Delete an existing image from the expense
  /// Shows confirmation dialog before deletion
  /// Marks image for deletion (actual deletion happens on save)
  Future<void> _deleteImage(Map<String, dynamic> imgObj) async {
    final cloudinaryId = imgObj['cloudinary_id']?.toString() ?? '';

    // If no cloudinary ID, just remove from list
    if (cloudinaryId.isEmpty) {
      setState(() => _existing.remove(imgObj));
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Remove image if confirmed
    if (confirmed == true) {
      setState(() => _existing.remove(imgObj));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image marked for deletion')),
        );
      }
    }
  }

  /// Validate form and save updated expense
  /// Returns updated expense data to previous screen
  void _save() {
    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    // Check if category is selected
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category')),
      );
      return;
    }

    // Prepare updated expense data
    final updated = {
      'id': widget.expense['id'] ?? widget.expense['_id'],
      'category': _category,
      'title': _titleCtrl.text.trim(),
      'date': _date.toIso8601String().split('T').first,
      'description': _noteCtrl.text.trim(),
      'existingImages': _existing,  // Images to keep
      'imageFiles': _newPicked,     // New images to upload
    };

    // Return updated data to previous screen
    Navigator.pop(context, updated);
  }

  /// Build image widget for display
  /// Handles both network URLs and local file paths
  /// Shows error placeholder if image fails to load
  Widget _buildImageWidget(String path, {double? width, double? height}) {
    final isUrl = path.startsWith('http://') || path.startsWith('https://');

    // Display network image for URLs or web platform
    if (isUrl || kIsWeb) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      );
    } else {
      // Display local file image for mobile platforms
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      );
    }
  }

  /// Show image preview dialog with zoom capability
  /// Allows viewing full-size image with pinch-to-zoom
  /// Provides delete option for existing images
  void _showImagePreview(String imagePath, {Map<String, dynamic>? imgObj}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Image with interactive zoom
            InteractiveViewer(
              child: _buildImageWidget(imagePath),
            ),

            // Close button (top-right)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),

            // Delete button for existing images (top-left)
            if (imgObj != null)
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _deleteImage(imgObj);
                  },
                  icon: const Icon(Icons.delete, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Available expense categories
    final categories = [
      'Light Bill',
      'Water Bill',
      'Internet Bill',
      'Salary',
      'Cleaning',
      'Rent',
      'Purchases'
    ];

    final expenseId = widget.expense['id'] ?? widget.expense['_id'] ?? '';
    final hasImages = _existing.isNotEmpty || _newPicked.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category dropdown field
              DropdownButtonFormField<String>(
                value: categories.contains(_category) ? _category : null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Select category' : null,
              ),
              const SizedBox(height: 12),

              // Title text field
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),

              // Date picker field
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(_date.toIso8601String().split('T').first),
                ),
              ),
              const SizedBox(height: 12),

              // Description text field (optional, multi-line)
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Image management section (only for expenses with ID)
              if (expenseId.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add photos button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _pickImages,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Add Photos'),
                          ),
                        ),

                        // Display images if any exist
                        if (hasImages) ...[
                          const SizedBox(height: 16),

                          // Display existing images from server
                          if (_existing.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _existing.map((imgObj) {
                                return GestureDetector(
                                  onTap: () => _showImagePreview(
                                    imgObj['url']!,
                                    imgObj: imgObj,
                                  ),
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Image display
                                          _buildImageWidget(
                                            imgObj['url']!,
                                          ),

                                          // "Tap to zoom" overlay at bottom
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 4,
                                                horizontal: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    Colors.black.withOpacity(0.7),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.search,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Tap to zoom',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          // Display newly picked images (not yet uploaded)
                          if (_newPicked.isNotEmpty) ...[
                            if (_existing.isNotEmpty) const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _newPicked.map((file) {
                                return GestureDetector(
                                  onTap: () => _showImagePreview(file.path),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              // Image display
                                              _buildImageWidget(file.path),

                                              // "Tap to zoom" overlay at bottom
                                              Positioned(
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                    horizontal: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [
                                                        Colors.black.withOpacity(0.7),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.search,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Tap to zoom',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Remove button for newly picked images (top-right)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => setState(() => _newPicked.remove(file)),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Update button
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Update Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}