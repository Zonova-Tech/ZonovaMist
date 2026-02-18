import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/rbac.dart';
import '../../../core/api/api_service.dart';
import '../../../shared/widgets/room_selector_widget.dart';
import '../../../shared/widgets/common_image_manager.dart';
import '../../../shared/widgets/rbac_gate.dart';
import '../../../shared/models/nic_data.dart';
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

  // Room selection
  Set<String> _selectedRooms = {};
  String _originalBookingId = '';

  // NIC detection state
  bool _nicDataApplied = false;

  /// Helper to extract decimal value from MongoDB Decimal128 format
  String _extractDecimalValue(dynamic value) {
    if (value == null) return '';

    if (value is Map && value.containsKey('\$numberDecimal')) {
      return value['\$numberDecimal'].toString();
    }

    if (value is num) {
      return value.toString();
    }

    if (value is String) {
      return value;
    }

    return '';
  }

  @override
  void initState() {
    super.initState();
    _originalBookingId = widget.booking['_id'];

    guestNameController = TextEditingController(text: widget.booking['guest_name']);
    phoneNoController = TextEditingController(text: widget.booking['phone_no']);
    notesController = TextEditingController(text: widget.booking['special_notes'] ?? '');
    guestAddressController = TextEditingController(text: widget.booking['guest_address'] ?? '');
    guestNicController = TextEditingController(text: widget.booking['guest_nic'] ?? '');
    adultCountController = TextEditingController(text: widget.booking['adult_count']?.toString() ?? '');
    childCountController = TextEditingController(text: widget.booking['child_count']?.toString() ?? '');

    totalPriceController = TextEditingController(
        text: _extractDecimalValue(widget.booking['total_price'])
    );
    advanceAmountController = TextEditingController(
        text: _extractDecimalValue(widget.booking['advance_amount'])
    );

    // Parse selected rooms
    final roomsStr = widget.booking['booked_room_no'] as String? ?? '';
    if (roomsStr.isNotEmpty) {
      _selectedRooms = roomsStr.split(',').map((r) => r.trim()).toSet();
    }

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

  // Handle NIC data from CommonImageManager
  void _handleNICDataSelected(NICData nicData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              nicData.hasValidData ? Icons.check_circle : Icons.warning,
              color: nicData.hasValidData ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Apply NIC Data?'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Confidence indicator
              LinearProgressIndicator(
                value: nicData.confidence,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  nicData.confidence > 0.7 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence: ${(nicData.confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(height: 24),

              const Text(
                'Do you want to fill the form with this NIC data?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              if (nicData.fullName != null)
                _buildPreviewRow('Guest Name', nicData.fullName!, nicData.fieldsExtracted.name),
              if (nicData.nicNumber != null)
                _buildPreviewRow('NIC Number', nicData.nicNumber!, nicData.fieldsExtracted.nic),
              if (nicData.dateOfBirth != null)
                _buildPreviewRow(
                  'Date of Birth',
                  '${nicData.dateOfBirth!.day}/${nicData.dateOfBirth!.month}/${nicData.dateOfBirth!.year}',
                  nicData.fieldsExtracted.dob,
                ),
              if (nicData.address != null)
                _buildPreviewRow('Address', nicData.address!, nicData.fieldsExtracted.address),

              if (nicData.errors.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  'Note: ${nicData.errors.length} issue${nicData.errors.length > 1 ? 's' : ''} found. Please verify the data.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _applyNICData(nicData);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('Apply'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, bool extracted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            extracted ? Icons.check_circle : Icons.help_outline,
            size: 16,
            color: extracted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _applyNICData(NICData nicData) {
    setState(() {
      _nicDataApplied = true;

      // Only fill empty fields to avoid overwriting user data
      if (nicData.fullName != null && guestNameController.text.isEmpty) {
        guestNameController.text = nicData.fullName!;
      }

      if (nicData.nicNumber != null && guestNicController.text.isEmpty) {
        guestNicController.text = nicData.nicNumber!;
      }

      if (nicData.dateOfBirth != null && birthday == null) {
        birthday = nicData.dateOfBirth;
      }

      if (nicData.address != null && guestAddressController.text.isEmpty) {
        guestAddressController.text = nicData.address!;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(child: Text('NIC data applied to form')),
            if (nicData.hasWarnings)
              const Icon(Icons.warning, color: Colors.amber, size: 20),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _handleRoomToggle(String room, bool selected) {
    setState(() {
      if (selected) {
        _selectedRooms.add(room);
      } else {
        _selectedRooms.remove(room);
      }
    });
  }

  Future<void> _saveBooking() async {
    if (_selectedRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one room')),
      );
      return;
    }

    final dio = ref.read(dioProvider);
    try {
      final roomsString = _selectedRooms.join(', ');

      final data = {
        'guest_name': guestNameController.text,
        'booked_room_no': roomsString,
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
    return RbacGate(
      permission: AppPermission.bookings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit Booking"),
          elevation: 0,
          actions: [
            if (_nicDataApplied)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'NIC Applied',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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
              RoomSelectorWidget(
                selectedRooms: _selectedRooms,
                checkinDate: checkinDate,
                checkoutDate: checkoutDate,
                excludeBookingId: _originalBookingId,
                onRoomToggle: _handleRoomToggle,
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

          // Photos & NIC Upload Section
          _buildCard(
            title: "Photos & Documents",
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_camera, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Upload guest photos or NIC for automatic data extraction',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  if (_nicDataApplied)
                    Icon(Icons.verified, color: Colors.green.shade600, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              CommonImageManager(
                entityType: 'Booking',
                entityId: _originalBookingId,
                onNICDataSelected: _handleNICDataSelected,
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
      ),
    );
  }
}
