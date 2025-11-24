import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseService {
  static const String baseUrl = 'http://localhost:5000/api/expense';

  static final cloudinary = CloudinaryPublic(
    'dqi0bndrs',
    'expenses_upload',
    cache: false,
  );

  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print('🔑 Token: $token');
      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  // =========================================================
  // CREATE EXPENSE
  // =========================================================
  static Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    try {
      print('📤 Starting createExpense...');

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login again.');
      }

      List<Map<String, String>> uploadedImages = [];
      if (data['imageFiles'] != null && data['imageFiles'] is List<XFile>) {
        print('📸 Uploading ${data['imageFiles'].length} images...');

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
            print('✅ Image uploaded: ${res.secureUrl}');
          } catch (e) {
            print('❌ Image upload failed: $e');
          }
        }
      }

      final payload = {
        'category': data['category'],
        'title': data['title'],
        'description': data['note'] ?? '',
        'amount': data['amount']?.toString() ?? '0',
        'date': data['date'] ?? DateTime.now().toIso8601String(),
        'images': uploadedImages,
      };

      print('📦 Payload: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        print('✅ Expense created successfully!');
        return result;
      } else {
        final err = json.decode(response.body);
        print('❌ Server Error: ${err['error']}');
        throw Exception(err['error'] ?? 'Failed to create expense');
      }
    } catch (e) {
      print('❌ Error in createExpense: $e');
      rethrow;
    }
  }

  // =========================================================
  // FETCH EXPENSES
  // =========================================================
  static Future<List<dynamic>> fetchExpenses() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login again.');
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      print('📡 Fetch Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch expenses');
      }
    } catch (e) {
      print('❌ Error in fetchExpenses: $e');
      rethrow;
    }
  }

  // =========================================================
  // UPDATE EXPENSE (FIXED)
  // =========================================================
  static Future<Map<String, dynamic>> updateExpense(String id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login again.');
      }

      print('📤 Starting updateExpense...');

      // 1. Keep existing images (already uploaded to Cloudinary)
      List<Map<String, String>> allImages = [];

      // Add existing Cloudinary images with full data
      if (data['existingImages'] != null && data['existingImages'] is List) {
        print('📷 Keeping ${data['existingImages'].length} existing images');
        for (var imgObj in data['existingImages']) {
          // ✅ Handle Map objects (full image data)
          if (imgObj is Map) {
            allImages.add({
              'url': imgObj['url']?.toString() ?? '',
              'cloudinary_id': imgObj['cloudinary_id']?.toString() ?? '',
              'filename': imgObj['filename']?.toString() ?? '',
            });
          }
          // Handle String URLs (fallback)
          else if (imgObj is String && imgObj.isNotEmpty) {
            allImages.add({
              'url': imgObj,
              'cloudinary_id': '',
              'filename': '',
            });
          }
        }
      }

      // 2. Upload new images to Cloudinary
      if (data['imageFiles'] != null && data['imageFiles'] is List) {
        print('📸 Uploading ${data['imageFiles'].length} new images...');

        for (var img in data['imageFiles']) {
          if (img is XFile) {
            try {
              final res = await cloudinary.uploadFile(
                CloudinaryFile.fromFile(img.path, folder: 'zonova_mist/expenses'),
              );
              allImages.add({
                'url': res.secureUrl,
                'cloudinary_id': res.publicId,
                'filename': img.name,
              });
              print('✅ New image uploaded: ${res.secureUrl}');
            } catch (e) {
              print('❌ Image upload failed: $e');
            }
          }
        }
      }

      final payload = {
        'category': data['category'],
        'title': data['title'],
        'description': data['description'] ?? data['note'] ?? '',
        'amount': data['amount']?.toString() ?? '0',
        'date': data['date'] ?? DateTime.now().toIso8601String(),
        'images': allImages,
      };

      print('📦 Update Payload: ${jsonEncode(payload)}');

      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(payload),
      );

      print('📡 Update Response Status: ${response.statusCode}');
      print('📡 Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Expense updated with images!');
        return json.decode(response.body);
      } else {
        final err = json.decode(response.body);
        throw Exception(err['error'] ?? 'Failed to update expense');
      }
    } catch (e) {
      print('❌ Error in updateExpense: $e');
      rethrow;
    }
  }

  // =========================================================
  // DELETE EXPENSE
  // =========================================================
  static Future<void> deleteExpense(String id) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login again.');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Expense deleted!');
      } else {
        throw Exception('Failed to delete expense');
      }
    } catch (e) {
      print('❌ Error in deleteExpense: $e');
      rethrow;
    }
  }
}
