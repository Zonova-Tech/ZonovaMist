import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import 'bookings_provider.dart';

class EditBookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;

  const EditBookingScreen({super.key, required this.booking});

  @override
  ConsumerState<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends ConsumerState<EditBookingScreen> {
  late TextEditingController clientNameController;
  late TextEditingController roomNoController;
  late TextEditingController dateController;
  late TextEditingController notesController;
  late TextEditingController birthdayController;
  late TextEditingController guestAddressController;
  late TextEditingController guestNicController;
  late TextEditingController childCountController;
  late TextEditingController advanceController;
  late String status;

  @override
  void initState() {
    super.initState();
    clientNameController = TextEditingController(text: widget.booking['guest_name']);
    roomNoController = TextEditingController(text: widget.booking['booked_room_no']?.toString());
    dateController = TextEditingController(text: widget.booking['checkin_date']);
    notesController = TextEditingController(text: widget.booking['special_notes'] ?? '');
    birthdayController = TextEditingController(text: widget.booking['birthday'] ?? '');
    guestAddressController = TextEditingController(text: widget.booking['guest_address'] ?? '');
    guestNicController = TextEditingController(text: widget.booking['guest_nic'] ?? '');
    childCountController = TextEditingController(text: widget.booking['child_count']?.toString() ?? '');
    advanceController = TextEditingController(text: widget.booking['advance']?.toString() ?? '');
    status = widget.booking['status'] ?? 'pending';
  }

  @override
  void dispose() {
    clientNameController.dispose();
    roomNoController.dispose();
    dateController.dispose();
    notesController.dispose();
    birthdayController.dispose();
    guestAddressController.dispose();
    guestNicController.dispose();
    childCountController.dispose();
    advanceController.dispose();
    super.dispose();
  }

  Future<void> _saveBooking() async {
    final dio = ref.read(dioProvider);
    try {
      await dio.patch('/bookings/${widget.booking['_id']}', data: {
        'guest_name': clientNameController.text,
        'booked_room_no': int.tryParse(roomNoController.text) ?? roomNoController.text,
        'checkin_date': dateController.text,
        'special_notes': notesController.text.isNotEmpty ? notesController.text : null,
        'birthday': birthdayController.text.isNotEmpty ? birthdayController.text : null,
        'guest_address': guestAddressController.text.isNotEmpty ? guestAddressController.text : null,
        'guest_nic': guestNicController.text.isNotEmpty ? guestNicController.text : null,
        'child_count': childCountController.text.isNotEmpty
            ? int.tryParse(childCountController.text)
            : null,
        'advance': advanceController.text.isNotEmpty
            ? double.tryParse(advanceController.text)
            : null,
        'status': status,
      });

      ref.invalidate(bookingsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update booking: $e')),
        );
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text("Edit Booking"), backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField("Guest Name", clientNameController),
            _buildTextField("Room No", roomNoController,
                inputType: TextInputType.number),
            _buildTextField("Check-in Date", dateController,
                inputType: TextInputType.datetime),

            // Optional fields
            _buildTextField("Guest Address", guestAddressController),
            _buildTextField("Guest NIC", guestNicController),
            _buildTextField("Child Count", childCountController,
                inputType: TextInputType.number),
            _buildTextField("Advance Payment (LKR)", advanceController,
                inputType: TextInputType.number),
            _buildTextField("Birthday (YYYY-MM-DD)", birthdayController,
                inputType: TextInputType.datetime),
            _buildTextField("Special Notes", notesController, maxLines: 3),

            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                  labelText: 'Status', border: OutlineInputBorder()),
              items: ['paid', 'pending', 'cancelled']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => status = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Save Booking",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
