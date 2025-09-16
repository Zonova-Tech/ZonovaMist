// edit_hotel_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import '../../../core/auth/hotels_provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/auth/hotels_provider.dart';

class EditHotelScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> hotel;

  const EditHotelScreen({super.key, required this.hotel});

  @override
  ConsumerState<EditHotelScreen> createState() => _EditHotelScreenState();
}

class _EditHotelScreenState extends ConsumerState<EditHotelScreen> {
  late TextEditingController priceController;
  late String status;

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(
      text: widget.hotel['price']?.toString() ?? '',
    );
    status = (widget.hotel['status'] as String?) ?? 'available';
  }

  Future<void> _saveChanges() async {
    final text = priceController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price cannot be empty')),
      );
      return;
    }

    final price = int.tryParse(text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number for price')),
      );
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.patch('/hotels/${widget.hotel['_id']}', data: {
        'price': price,
        'status': status,
      });

      if ((resp.statusCode ?? 500) >= 200 && (resp.statusCode ?? 500) < 300) {
        ref.refresh(hotelsProvider);
        if (!mounted) return;
        Navigator.of(context).pop(true); // ✅ return success
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
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'available', child: Text('Available')),
                DropdownMenuItem(value: 'booked', child: Text('Booked')),
                DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
              ],
              onChanged: (val) => setState(() => status = val ?? status),
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
