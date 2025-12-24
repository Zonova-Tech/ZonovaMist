import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:http/http.dart' as http;

class ExpenseService {
  static String get baseUrl => '${AppConfig.apiBaseUrl}/expenses';

  static final cloudinary = CloudinaryPublic(
    'dqi0bndrs',
    'expenses_upload',
    cache: false,
  );

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

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
        } catch (e) {}
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

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final err = json.decode(response.body);
      throw Exception(err['error'] ?? 'Failed to create expense');
    }
  }

  static Future<List<dynamic>> fetchExpenses() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to fetch expenses');
  }

  static Future<Map<String, dynamic>> updateExpense(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    List<Map<String, String>> allImages = [];

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
        } catch (e) {}
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

    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) return json.decode(response.body);
    final err = json.decode(response.body);
    throw Exception(err['error'] ?? 'Failed to update expense');
  }

  static Future<void> deleteExpense(String id) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) throw Exception('Failed to delete expense');
  }
}
