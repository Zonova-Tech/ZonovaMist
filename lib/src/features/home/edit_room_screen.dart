import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/auth/rooms_provider.dart';

class EditRoomScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> room;

  const EditRoomScreen({super.key, required this.room});

  @override
  ConsumerState<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends ConsumerState<EditRoomScreen> {
  late TextEditingController priceController;
  late String status;

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(
      text: widget.room['pricePerNight']?.toString() ?? '',
    );
    status = (widget.room['status'] as String?) ?? 'available';
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
      final resp = await dio.patch('/rooms/${widget.room['_id']}', data: {
        'pricePerNight': price,
        'status': status,
      });

      if ((resp.statusCode ?? 500) >= 200 && (resp.statusCode ?? 500) < 300) {
        ref.refresh(roomsProvider);
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
      appBar: AppBar(title: const Text('Edit Room')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price Per Night',
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
                DropdownMenuItem(value: 'available', child: Text('available')),
                DropdownMenuItem(value: 'occupied', child: Text('occupied')),
                DropdownMenuItem(value: 'maintenance', child: Text('maintenance')),
              ],
              onChanged: (val) => setState(() => status = val ?? status),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
