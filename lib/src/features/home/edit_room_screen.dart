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
  late TextEditingController bedCountController;
  late TextEditingController maxOccupancyController;
  late String status;

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(
      text: widget.room['pricePerNight']?.toString() ?? '',
    );
    bedCountController = TextEditingController(
      text: widget.room['bedCount']?.toString() ?? '',
    );
    maxOccupancyController = TextEditingController(
      text: widget.room['maxOccupancy']?.toString() ?? '',
    );
    status = (widget.room['status'] as String?) ?? 'available';
  }

  Future<void> _saveChanges() async {
    final priceText = priceController.text.trim();
    final bedsText = bedCountController.text.trim();
    final maxText = maxOccupancyController.text.trim();

    if (priceText.isEmpty || bedsText.isEmpty || maxText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    final price = int.tryParse(priceText);
    final beds = int.tryParse(bedsText);
    final max = int.tryParse(maxText);

    if (price == null || beds == null || max == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric values')),
      );
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.patch('/rooms/${widget.room['_id']}', data: {
        'pricePerNight': price,
        'bedCount': beds,
        'maxOccupancy': max,
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
                labelText: 'Price Per Night (LKR)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: bedCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Beds Count',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: maxOccupancyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum Occupancy',
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
                DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
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
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
