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
    priceController = TextEditingController(text: widget.room['pricePerNight'].toString());
    status = widget.room['status'];
  }

  Future<void> _saveChanges() async {
    final dio = ref.read(dioProvider);
    await dio.patch('/rooms/${widget.room['_id']}', data: {
      'pricePerNight': int.parse(priceController.text),
      'status': status,
    });
    ref.invalidate(roomsProvider);
    Navigator.pop(context);
    Navigator.pop(context); // pop details page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Room')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price Per Night'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ['available', 'occupied', 'maintenance']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => status = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save Changes'),
            )
          ],
        ),
      ),
    );
  }
}
