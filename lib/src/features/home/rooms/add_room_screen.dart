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

      await dio.post('/rooms', data: {
        'roomNumber': _roomNumberController.text,
        'type': _typeController.text,
        'floor': int.parse(_floorController.text),
        'bedCount': int.parse(_bedCountController.text),
        'maxOccupancy': int.parse(_maxOccupancyController.text),
        'pricePerNight': double.parse(_priceController.text),
        'status': _status,
      });

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(labelText: 'Room Number'),
                validator: (value) =>
                value!.isEmpty ? 'Enter room number' : null,
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Room Type'),
                validator: (value) =>
                value!.isEmpty ? 'Enter room type' : null,
              ),
              TextFormField(
                controller: _floorController,
                decoration: const InputDecoration(labelText: 'Floor'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _bedCountController,
                decoration: const InputDecoration(labelText: 'Bed Count'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _maxOccupancyController,
                decoration:
                const InputDecoration(labelText: 'Max Occupancy'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _priceController,
                decoration:
                const InputDecoration(labelText: 'Price Per Night'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                  DropdownMenuItem(
                      value: 'maintenance', child: Text('Maintenance')),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value.toString();
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addRoom,
                child: const Text('Add Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
