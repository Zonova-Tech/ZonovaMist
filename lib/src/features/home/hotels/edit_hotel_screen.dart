// edit_hotel_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import '../../../core/auth/hotels_provider.dart';

class EditHotelScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> hotel;

  const EditHotelScreen({super.key, required this.hotel});

  @override
  ConsumerState<EditHotelScreen> createState() => _EditHotelScreenState();
}

class _EditHotelScreenState extends ConsumerState<EditHotelScreen> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController phoneController;
  late String status;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.hotel['name']?.toString() ?? '',
    );
    descriptionController = TextEditingController(
      text: widget.hotel['description'] ?? '',
    );
    phoneController = TextEditingController(
      text: widget.hotel['phone'] ?? '',
    );
    status = (widget.hotel['status'] as String?) ?? 'available';
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hotel name cannot be empty')),
      );
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.patch('/hotels/${widget.hotel['_id']}', data: {
        'name': name,
        'status': status,
        'description': description,
        'phone': phone,
      });

      if ((resp.statusCode ?? 500) >= 200 && (resp.statusCode ?? 500) < 300) {
        ref.refresh(hotelsProvider);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Hotel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Hotel Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                labelText: 'Availability',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'available', child: Text('Available')),
                DropdownMenuItem(value: 'booked', child: Text('Booked')),
                DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
              ],
              onChanged: (val) => setState(() => status = val ?? status),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}