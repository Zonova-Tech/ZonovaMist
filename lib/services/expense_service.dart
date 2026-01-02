import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:http/http.dart' as http;

class ExpenseService {

  static String get baseUrl => '${AppConfig.apiBaseUrl}/expenses';

  static final cloudinary = CloudinaryPublic(
    AppConfig.cloudinaryCloudName,
    'expenses_upload',
    cache: false,
  );


  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Create a new expense
  static Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    // Check authentication
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    // Upload images to Cloudinary
    List<Map<String, String>> uploadedImages = [];

    if (data['imageFiles'] != null && data['imageFiles'] is List<XFile>) {
      for (var img in data['imageFiles']) {
        try {
          // Upload image file to Cloudinary
          final res = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(img.path, folder: 'zonova_mist/expenses'),
          );
          // Store image URL and metadata
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

    // Send POST request to create expense
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(payload),
    );

    // Handle response
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final err = json.decode(response.body);
      throw Exception(err['error'] ?? 'Failed to create expense');
    }
  }

  // Fetch all expenses from API
  static Future<List<dynamic>> fetchExpenses() async {
    // Check authentication
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    // Send GET request to fetch expenses
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    // Return expense list if successful
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to fetch expenses');
  }

  //Update an existing expense
  static Future<Map<String, dynamic>> updateExpense(String id, Map<String, dynamic> data) async {
    // Check authentication
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

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
          // Upload new image file to Cloudinary
          final res = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(img.path, folder: 'zonova_mist/expenses'),
          );
          // Add uploaded image to list
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

    // Send PUT request to update expense
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(payload),
    );

    // Handle response
    if (response.statusCode == 200) return json.decode(response.body);
    final err = json.decode(response.body);
    throw Exception(err['error'] ?? 'Failed to update expense');
  }

  // Delete an expense
  static Future<void> deleteExpense(String id) async {
    // Check authentication
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    // Send DELETE request
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    // Throw exception if deletion failed
    if (response.statusCode != 200) throw Exception('Failed to delete expense');
  }
}