import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'edit_expense_page.dart';

class ViewExpensePage extends StatelessWidget {
  final Map<String, dynamic> expense;
  const ViewExpensePage({super.key, required this.expense});

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'light bill':
        return Colors.amber;
      case 'water bill':
        return Colors.blue;
      case 'internet bill':
        return Colors.purple;
      case 'salary':
        return Colors.green;
      case 'cleaning':
        return Colors.teal;
      case 'rent':
        return Colors.red;
      case 'purchases':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic dateField) {
    if (dateField == null) return '';
    try {
      if (dateField is String) {
        if (dateField.contains('T')) {
          return dateField.split('T')[0];
        }
        return dateField;
      }
      if (dateField is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(dateField);
        return dt.toIso8601String().split('T')[0];
      }
      if (dateField is double) {
        final dt = DateTime.fromMillisecondsSinceEpoch(dateField.toInt());
        return dt.toIso8601String().split('T')[0];
      }
      if (dateField is DateTime) {
        return dateField.toIso8601String().split('T')[0];
      }
      return dateField.toString();
    } catch (e) {
      return dateField.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = expense['title']?.toString() ?? 'No Title';
    final category = expense['category']?.toString() ?? 'No Category';
    final rawDate = expense['date'];
    final displayDate = _formatDate(rawDate);
    final description = expense['description']?.toString() ??
        expense['note']?.toString() ??
        '';

    final images = expense['images'] ?? expense['imagePaths'] ?? [];
    final imageFiles = expense['imageFiles'] ?? [];
    final existingImages = expense['existingImages'] ?? [];

    List<String> imageUrls = [];

    if (images is List) {
      imageUrls.addAll(images.map((img) {
        if (img is String) return img;
        if (img is Map) return img['url']?.toString() ?? '';
        return '';
      }).where((s) => s.isNotEmpty));
    }

    if (existingImages is List && existingImages.isNotEmpty) {
      for (var url in existingImages) {
        if (url is String && url.isNotEmpty && !imageUrls.contains(url)) {
          imageUrls.add(url);
        }
      }
    }

    if (imageFiles is List && imageFiles.isNotEmpty) {
      for (var file in imageFiles) {
        try {
          if (file != null && file.path != null) {
            imageUrls.add(file.path.toString());
          }
        } catch (_) {}
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final res = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => EditExpensePage(expense: expense)),
              );
              if (res != null && context.mounted) {
                Navigator.pop(context, res);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: _getCategoryColor(category).withOpacity(0.2),
                      child: Icon(
                        Icons.receipt_long,
                        size: 60,
                        color: _getCategoryColor(category),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getCategoryColor(category),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(category),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),


            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Section - Left: "Date" icon + text, Right: actual date
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: displayDate.isNotEmpty
                              ? Text(
                            displayDate,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.right,
                          )
                              : Text(
                            'No date provided',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),


                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: description.isNotEmpty
                              ? Text(
                            description,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.right,
                          )
                              : Text(
                            'No description provided',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bill & Receipt Section
            if (imageUrls.isNotEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.blue.shade700),
                          const SizedBox(width: 5),
                          const Text(
                            'Bill & Receipt',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: imageUrls.length,
                        itemBuilder: (context, i) {
                          final url = imageUrls[i];
                          final isUrl = url.startsWith('http://') || url.startsWith('https://');

                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  child: (isUrl || kIsWeb)
                                      ? Image.network(url, fit: BoxFit.contain)
                                      : Image.file(File(url), fit: BoxFit.contain),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (isUrl || kIsWeb)
                                  ? Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                ),
                              )
                                  : Image.file(
                                File(url),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}