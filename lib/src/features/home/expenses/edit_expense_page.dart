import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class EditExpensePage extends StatefulWidget {
  final Map<String, dynamic> expense;

  const EditExpensePage({super.key, required this.expense});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  String? _category;
  final _titleCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  final _noteCtrl = TextEditingController();
  final List<XFile> _newPicked = [];
  late List<Map<String, dynamic>> _existing;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _category = widget.expense['category']?.toString();
    _titleCtrl.text = widget.expense['title']?.toString() ?? '';

    final dateStr = widget.expense['date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      _date = DateTime.tryParse(dateStr) ?? DateTime.now();
    }

    _noteCtrl.text = widget.expense['description']?.toString() ?? '';

    final images = widget.expense['images'];
    if (images != null && images is List && images.isNotEmpty) {
      _existing = images.map((img) {
        if (img is Map) {
          return {
            'url': img['url']?.toString() ?? '',
            'cloudinary_id': img['cloudinary_id']?.toString() ?? '',
            'filename': img['filename']?.toString() ?? '',
            'fileSize': img['fileSize'] ?? 0,
            'mimeType': img['mimeType']?.toString() ?? 'image/jpeg',
          };
        }
        if (img is String) {
          return {
            'url': img,
            'cloudinary_id': '',
            'filename': '',
            'fileSize': 0,
            'mimeType': 'image/jpeg',
          };
        }
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
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() => _newPicked.addAll(images));
    }
  }

  Future<void> _selectDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  // ✅ Delete image with confirmation dialog
  Future<void> _deleteImage(Map<String, dynamic> imgObj) async {
    final cloudinaryId = imgObj['cloudinary_id']?.toString() ?? '';

    if (cloudinaryId.isEmpty) {
      setState(() => _existing.remove(imgObj));
      return;
    }

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

    if (confirmed == true) {
      setState(() => _existing.remove(imgObj));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image marked for deletion')),
        );
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category')),
      );
      return;
    }

    final updated = {
      'id': widget.expense['id'] ?? widget.expense['_id'],
      'category': _category,
      'title': _titleCtrl.text.trim(),
      'date': _date.toIso8601String().split('T').first,
      'description': _noteCtrl.text.trim(),
      'existingImages': _existing,
      'imageFiles': _newPicked,
    };

    Navigator.pop(context, updated);
  }

  Widget _buildImageWidget(String path, {double? width, double? height}) {
    final isUrl = path.startsWith('http://') || path.startsWith('https://');

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

  // ✅ Show image preview with delete button (staff page style)
  void _showImagePreview(String imagePath, {Map<String, dynamic>? imgObj}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: _buildImageWidget(imagePath),
            ),
            // Close button (top right)
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
            // ✅ Delete button (top left) - only for existing images
            if (imgObj != null)
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close preview dialog
                    await _deleteImage(imgObj); // Delete image
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
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(_date.toIso8601String().split('T').first),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Document Upload Section (Staff style layout)
              if (expenseId.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add Photos Button
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

                        // Images Display
                        if (hasImages) ...[
                          const SizedBox(height: 16),

                          // Existing Images
                          if (_existing.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _existing.map((imgObj) {
                                return GestureDetector(
                                  onTap: () => _showImagePreview(
                                    imgObj['url']!,
                                    imgObj: imgObj, // ✅ Pass imgObj for delete
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
                                          _buildImageWidget(
                                            imgObj['url']!,
                                          ),
                                          // Tap to zoom overlay
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

                          // New Images
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
                                              _buildImageWidget(file.path),
                                              // Tap to zoom overlay
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
                                      // Close button for new images
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

              // Update Button
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
