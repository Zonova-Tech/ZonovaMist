import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import 'bookings_provider.dart';
import 'package:intl/intl.dart';

class EditBookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;

  const EditBookingScreen({super.key, required this.booking});

  @override
  ConsumerState<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends ConsumerState<EditBookingScreen> {
  late TextEditingController guestNameController;
  late TextEditingController roomNoController;
  late TextEditingController phoneNoController;
  late TextEditingController notesController;
  late TextEditingController guestAddressController;
  late TextEditingController guestNicController;
  late TextEditingController adultCountController;
  late TextEditingController childCountController;
  late TextEditingController totalPriceController;
  late TextEditingController advanceAmountController;
  DateTime? checkinDate;
  DateTime? checkoutDate;
  DateTime? birthday;
  late String status;

  /// Helper to extract decimal value from MongoDB Decimal128 format
  String _extractDecimalValue(dynamic value) {
    if (value == null) return '';

    // Handle Decimal128 format: {$numberDecimal: "5000"}
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return value['\$numberDecimal'].toString();
    }

    // Handle regular numbers
    if (value is num) {
      return value.toString();
    }

    // Handle strings
    if (value is String) {
      return value;
    }

    return '';
  }

  @override
  void initState() {
    super.initState();
    guestNameController = TextEditingController(text: widget.booking['guest_name']);
    roomNoController = TextEditingController(text: widget.booking['booked_room_no']?.toString());
    phoneNoController = TextEditingController(text: widget.booking['phone_no']);
    notesController = TextEditingController(text: widget.booking['special_notes'] ?? '');
    guestAddressController = TextEditingController(text: widget.booking['guest_address'] ?? '');
    guestNicController = TextEditingController(text: widget.booking['guest_nic'] ?? '');
    adultCountController = TextEditingController(text: widget.booking['adult_count']?.toString() ?? '');
    childCountController = TextEditingController(text: widget.booking['child_count']?.toString() ?? '');

    // ✅ Fixed: Extract decimal values properly
    totalPriceController = TextEditingController(
        text: _extractDecimalValue(widget.booking['total_price'])
    );
    advanceAmountController = TextEditingController(
        text: _extractDecimalValue(widget.booking['advance_amount'])
    );

    // Parse dates
    if (widget.booking['checkin_date'] != null) {
      try {
        checkinDate = DateTime.parse(widget.booking['checkin_date']);
      } catch (e) {
        print('Error parsing checkin date: $e');
      }
    }
    if (widget.booking['checkout_date'] != null) {
      try {
        checkoutDate = DateTime.parse(widget.booking['checkout_date']);
      } catch (e) {
        print('Error parsing checkout date: $e');
      }
    }
    if (widget.booking['birthday'] != null) {
      try {
        birthday = DateTime.parse(widget.booking['birthday']);
      } catch (e) {
        print('Error parsing birthday: $e');
      }
    }

    status = widget.booking['status'] ?? 'pending';
  }

  @override
  void dispose() {
    guestNameController.dispose();
    roomNoController.dispose();
    phoneNoController.dispose();
    notesController.dispose();
    guestAddressController.dispose();
    guestNicController.dispose();
    adultCountController.dispose();
    childCountController.dispose();
    totalPriceController.dispose();
    advanceAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, String type) async {
    DateTime initialDate = DateTime.now();
    if (type == 'checkin' && checkinDate != null) {
      initialDate = checkinDate!;
    } else if (type == 'checkout' && checkoutDate != null) {
      initialDate = checkoutDate!;
    } else if (type == 'birthday' && birthday != null) {
      initialDate = birthday!;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: type == 'birthday' ? DateTime(1900) : DateTime(2020),
      lastDate: type == 'birthday' ? DateTime.now() : DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        if (type == 'checkin') {
          checkinDate = selected;
        } else if (type == 'checkout') {
          checkoutDate = selected;
        } else if (type == 'birthday') {
          birthday = selected;
        }
      });
    }
  }

  Future<void> _saveBooking() async {
    final dio = ref.read(dioProvider);
    try {
      final data = {
        'guest_name': guestNameController.text,
        'booked_room_no': roomNoController.text,
        'phone_no': phoneNoController.text,
        'status': status,
        if (checkinDate != null) 'checkin_date': checkinDate!.toIso8601String(),
        if (checkoutDate != null) 'checkout_date': checkoutDate!.toIso8601String(),
        if (guestAddressController.text.isNotEmpty)
          'guest_address': guestAddressController.text,
        if (guestNicController.text.isNotEmpty)
          'guest_nic': guestNicController.text,
        if (adultCountController.text.isNotEmpty)
          'adult_count': int.tryParse(adultCountController.text),
        if (childCountController.text.isNotEmpty)
          'child_count': int.tryParse(childCountController.text),
        if (totalPriceController.text.isNotEmpty)
          'total_price': double.tryParse(totalPriceController.text),
        if (advanceAmountController.text.isNotEmpty)
          'advance_amount': double.tryParse(advanceAmountController.text),
        if (birthday != null) 'birthday': birthday!.toIso8601String(),
        if (notesController.text.isNotEmpty)
          'special_notes': notesController.text,
      };

      await dio.patch('/bookings/${widget.booking['_id']}', data: data);

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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    int? minLines,
  }) {
    // Determine if this is a multi-line field
    final isMultiline = maxLines == null || (maxLines > 1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
        maxLines: maxLines,
        minLines: minLines,
        textInputAction: isMultiline
            ? TextInputAction.newline
            : TextInputAction.done,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedDate == null
                          ? 'Select Date'
                          : dateFormat.format(selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selectedDate == null ? FontWeight.normal : FontWeight.w500,
                        color: selectedDate == null ? Colors.grey.shade400 : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Booking"),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: "Guest Information",
            children: [
              _buildTextField(
                label: 'Guest Name',
                controller: guestNameController,
              ),
              _buildTextField(
                label: 'NIC',
                controller: guestNicController,
              ),
              _buildTextField(
                label: 'Phone Number',
                controller: phoneNoController,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                label: 'Address',
                controller: guestAddressController,
                maxLines: null,
                minLines: 2,
              ),
            ],
          ),

          _buildCard(
            title: "Booking Details",
            children: [
              _buildTextField(
                label: 'Room Number(s)',
                controller: roomNoController,
              ),
              _buildDateSelector(
                label: 'Check-in Date',
                selectedDate: checkinDate,
                onTap: () => _pickDate(context, 'checkin'),
                icon: Icons.login,
              ),
              _buildDateSelector(
                label: 'Check-out Date',
                selectedDate: checkoutDate,
                onTap: () => _pickDate(context, 'checkout'),
                icon: Icons.logout,
              ),
              _buildDateSelector(
                label: 'Birthday',
                selectedDate: birthday,
                onTap: () => _pickDate(context, 'birthday'),
                icon: Icons.cake,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Adults',
                      controller: adultCountController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Children',
                      controller: childCountController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),

          _buildCard(
            title: "Payment Information",
            children: [
              _buildTextField(
                label: 'Total Price (LKR)',
                controller: totalPriceController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                label: 'Advance Amount (LKR)',
                controller: advanceAmountController,
                keyboardType: TextInputType.number,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(
                    labelText: 'Payment Status',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Row(
                        children: [
                          Icon(Icons.pending, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 12),
                          const Text('Pending'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'advance_paid',
                      child: Row(
                        children: [
                          Icon(Icons.payments, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 12),
                          const Text('Advance Paid'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'paid',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 12),
                          const Text('Paid'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          const Text('Cancelled'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => status = val!),
                ),
              ),
            ],
          ),

          _buildCard(
            title: "Additional Notes",
            children: [
              _buildTextField(
                label: 'Special Notes',
                controller: notesController,
                maxLines: null,
                minLines: 4,
              ),
            ],
          ),

          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saveBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              "Save Changes",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}