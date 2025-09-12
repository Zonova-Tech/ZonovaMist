import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import 'package:intl/intl.dart';

class AddBookingScreen extends ConsumerStatefulWidget {
  const AddBookingScreen({super.key});

  @override
  ConsumerState<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends ConsumerState<AddBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _guestNicController = TextEditingController();
  final _guestNameController = TextEditingController();
  final _bookedRoomNoController = TextEditingController();
  DateTime? _checkinDate;
  DateTime? _checkoutDate;
  DateTime? _birthday;
  final _phoneNoController = TextEditingController();
  final _adultCountController = TextEditingController();
  final _childCountController = TextEditingController();
  final _guestAddressController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _specialNotesController = TextEditingController();
  final _advanceAmountController = TextEditingController();
  String _status = 'paid';

  Future<void> _pickDate(BuildContext context, bool isCheckin) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() {
        if (isCheckin) {
          _checkinDate = selected;
        } else {
          _checkoutDate = selected;
        }
      });
    }
  }

  Future<void> _pickBirthday(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() {
        _birthday = selected;
      });
    }
  }

  Future<void> _addBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_checkinDate == null || _checkoutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select check-in and check-out dates')),
      );
      return;
    }

    try {
      final dio = ref.read(dioProvider);

      final data = {
        'guest_nic': _guestNicController.text,
        'guest_name': _guestNameController.text,
        'booked_room_no': _bookedRoomNoController.text,
        'checkin_date': _checkinDate!.toIso8601String(),
        'checkout_date': _checkoutDate!.toIso8601String(),
        'birthday': _birthday?.toIso8601String(), // safe null check
        'phone_no': _phoneNoController.text,
        'adult_count': int.tryParse(_adultCountController.text) ?? 0,
        'child_count': int.tryParse(_childCountController.text) ?? 0,
        'guest_address': _guestAddressController.text,
        'total_price': double.tryParse(_totalPriceController.text) ?? 0,
        'special_notes': _specialNotesController.text,
        'advance_amount': double.tryParse(_advanceAmountController.text) ?? 0,
        'status': _status,
      };

      print("➡️ Sending booking data: $data"); // Debug log

      final response = await dio.post('/bookings', data: data);

      print("✅ Booking added successfully: ${response.data}");

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, stack) {
      print("❌ Error adding booking: $e");
      print(stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add booking: $e')),
        );
      }
    }
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(title: const Text('Add Booking')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildCard(
                title: "Guest Info",
                children: [
                  TextFormField(
                    controller: _guestNicController,
                    decoration: const InputDecoration(labelText: 'Guest NIC'),
                    validator: (v) => v!.isEmpty ? 'Enter guest NIC' : null,
                  ),
                  TextFormField(
                    controller: _guestNameController,
                    decoration: const InputDecoration(labelText: 'Guest Name'),
                    validator: (v) => v!.isEmpty ? 'Enter guest name' : null,
                  ),
                  TextFormField(
                    controller: _guestAddressController,
                    decoration: const InputDecoration(labelText: 'Guest Address'),
                  ),
                  TextFormField(
                    controller: _phoneNoController,
                    decoration: const InputDecoration(labelText: 'Phone No'),
                  ),
                ],
              ),
              _buildCard(
                title: "Booking Details",
                children: [
                  TextFormField(
                    controller: _bookedRoomNoController,
                    decoration: const InputDecoration(labelText: 'Booked Room No(s)'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_checkinDate == null
                              ? 'Select Check-in Date'
                              : dateFormat.format(_checkinDate!)),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _pickDate(context, true),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_checkoutDate == null
                              ? 'Select Check-out Date'
                              : dateFormat.format(_checkoutDate!)),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _pickDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_birthday == null
                        ? 'Select Birthday'
                        : dateFormat.format(_birthday!)),
                    trailing: const Icon(Icons.cake),
                    onTap: () => _pickBirthday(context),
                  ),
                  TextFormField(
                    controller: _adultCountController,
                    decoration: const InputDecoration(labelText: 'Adult Count'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _childCountController,
                    decoration: const InputDecoration(labelText: 'Child Count'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              _buildCard(
                title: "Payment Info",
                children: [
                  TextFormField(
                    controller: _totalPriceController,
                    decoration: const InputDecoration(labelText: 'Total Price'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _advanceAmountController,
                    decoration: const InputDecoration(labelText: 'Advance Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _status = value.toString();
                      });
                    },
                  ),
                ],
              ),
              _buildCard(
                title: "Other",
                children: [
                  TextFormField(
                    controller: _specialNotesController,
                    decoration: const InputDecoration(labelText: 'Special Notes'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addBooking,
                child: const Text('Add Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
