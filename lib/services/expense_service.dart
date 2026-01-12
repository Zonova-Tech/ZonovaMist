import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../config.dart';
import '../src/core/api/api_service.dart'; // Adjust path as needed

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService(ref.read(dioProvider));
});

class ExpenseService {
  final Dio _dio;

  ExpenseService(this._dio);

  static final cloudinary = CloudinaryPublic(
    AppConfig.cloudinaryCloudName,
    'expenses_upload',
    cache: false,
  );


  // Create a new expense
  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    // Upload images to Cloudinary
    List<Map<String, String>> uploadedImages = [];

    if (data['imageFiles'] != null && data['imageFiles'] is List<XFile>) {
      for (var img in data['imageFiles']) {
        try {
          final res = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(img.path, folder: 'zonova_mist/expenses'),
          );
          uploadedImages.add({
            'url': res.secureUrl,
            'cloudinary_id': res.publicId,
            'filename': img.name,
          });
        } catch (e) {
          // Silently skip failed uploads
        }
      }
    }

    // Prepare expense payload for API
    final payload = {
      'category': data['category'],
      'title': data['title'],
      'description': data['note'] ?? '',
      'amount': data['amount']?.toString() ?? '0',
      'date': data['date'] ?? DateTime.now().toIso8601String(),
      'images': uploadedImages,
    };

    final response = await _dio.post('/expenses', data: payload);
    return response.data;
  }

  // Fetch all expenses from API
  Future<List<dynamic>> fetchExpenses() async {
    final response = await _dio.get('/expenses');
    return response.data;
  }

  // Update an existing expense
  Future<Map<String, dynamic>> updateExpense(String id, Map<String, dynamic> data) async {
    // Build complete images list (existing + new)
    List<Map<String, String>> allImages = [];

    // Process existing images to keep
    if (data['existingImages'] != null && data['existingImages'] is List) {
      for (var imgObj in data['existingImages']) {
        if (imgObj is Map) {
          allImages.add({
            'url': imgObj['url']?.toString() ?? '',
            'cloudinary_id': imgObj['cloudinary_id']?.toString() ?? '',
            'filename': imgObj['filename']?.toString() ?? '',
          });
        } else if (imgObj is String && imgObj.isNotEmpty) {
          allImages.add({'url': imgObj, 'cloudinary_id': '', 'filename': ''});
        }
      }
    }

    // Upload new images to Cloudinary
    if (data['imageFiles'] != null && data['imageFiles'] is List<XFile>) {
      for (var img in data['imageFiles']) {
        try {
          final res = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(img.path, folder: 'zonova_mist/expenses'),
          );
          allImages.add({
            'url': res.secureUrl,
            'cloudinary_id': res.publicId,
            'filename': img.name,
          });
        } catch (e) {
          // Silently skip failed uploads
        }
      }
    }

    // Prepare updated expense payload
    final payload = {
      'category': data['category'],
      'title': data['title'],
      'description': data['description'] ?? data['note'] ?? '',
      'amount': data['amount']?.toString() ?? '0',
      'date': data['date'] ?? DateTime.now().toIso8601String(),
      'images': allImages,
    };

    final response = await _dio.put('/expenses/$id', data: payload);
    return response.data;
  }

  // Delete an expense
  Future<void> deleteExpense(String id) async {
    await _dio.delete('/expenses/$id');
  }
}