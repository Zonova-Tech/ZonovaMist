import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';

class AddRoomScreen extends ConsumerStatefulWidget {
  const AddRoomScreen({super.key});

  @override
  ConsumerState<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends ConsumerState<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _typeController = TextEditingController();
  final _floorController = TextEditingController();
  final _bedCountController = TextEditingController();
  final _maxOccupancyController = TextEditingController();
  final _priceController = TextEditingController();
  String _status = 'available';

  Future<void> _addRoom() async {
    if (_formKey.currentState!.validate()) {
      final dio = ref.read(dioProvider);

      try {
        await dio.post('/rooms', data: {
          'roomNumber': _roomNumberController.text,
          'type': _typeController.text,
          'floor': int.parse(_floorController.text),
          'bedCount': int.parse(_bedCountController.text),
          'maxOccupancy': int.parse(_maxOccupancyController.text),
          'pricePerNight': double.parse(_priceController.text),
          'status': _status,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room added successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add room: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Room'), backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter room number' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Room Type',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter room type' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _floorController,
                decoration: const InputDecoration(
                  labelText: 'Floor',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _bedCountController,
                decoration: const InputDecoration(
                  labelText: 'Bed Count',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _maxOccupancyController,
                decoration: const InputDecoration(
                  labelText: 'Max Occupancy',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price Per Night',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                  DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value.toString();
                  });
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addRoom,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Add Room',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
