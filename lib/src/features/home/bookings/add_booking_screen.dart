import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/rbac.dart';
import '../../../core/api/api_service.dart';
import '../../../shared/widgets/room_selector_widget.dart';
import '../../../shared/widgets/common_image_manager.dart';
import '../../../shared/widgets/rbac_gate.dart';
import '../../../shared/models/nic_data.dart';
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
  String _status = 'pending';

  // Room selection - now managed by widget but state kept here
  Set<String> _selectedRooms = {};

  // NIC detection state
  String _bookingId = '';
  bool _nicDataApplied = false;

  @override
  void initState() {
    super.initState();
  }

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

  void _handleRoomToggle(String room, bool selected) {
    setState(() {
      if (selected) {
        _selectedRooms.add(room);
      } else {
        _selectedRooms.remove(room);
      }
    });
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
      if (nicData.fullName != null && _guestNameController.text.isEmpty) {
        _guestNameController.text = nicData.fullName!;
      }

      if (nicData.nicNumber != null && _guestNicController.text.isEmpty) {
        _guestNicController.text = nicData.nicNumber!;
      }

      if (nicData.dateOfBirth != null && _birthday == null) {
        _birthday = nicData.dateOfBirth;
      }

      if (nicData.address != null && _guestAddressController.text.isEmpty) {
        _guestAddressController.text = nicData.address!;
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

  Future<void> _addBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_checkinDate == null || _checkoutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select check-in and check-out dates')),
      );
      return;
    }

    if (_selectedRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one room')),
      );
      return;
    }

    try {
      final dio = ref.read(dioProvider);

      final roomsString = _selectedRooms.join(', ');

      final data = {
        'guest_name': _guestNameController.text,
        'booked_room_no': roomsString,
        'checkin_date': _checkinDate!.toIso8601String(),
        'checkout_date': _checkoutDate!.toIso8601String(),
        'phone_no': _phoneNoController.text,
        'adult_count': int.tryParse(_adultCountController.text) ?? 0,
        'total_price': double.tryParse(_totalPriceController.text) ?? 0,
        'status': _status,
        if (_guestNicController.text.isNotEmpty)
          'guest_nic': _guestNicController.text,
        if (_guestAddressController.text.isNotEmpty)
          'guest_address': _guestAddressController.text,
        if (_childCountController.text.isNotEmpty)
          'child_count': int.tryParse(_childCountController.text) ?? 0,
        if (_advanceAmountController.text.isNotEmpty)
          'advance_amount': double.tryParse(_advanceAmountController.text) ?? 0,
        if (_specialNotesController.text.isNotEmpty)
          'special_notes': _specialNotesController.text,
        if (_birthday != null)
          'birthday': _birthday!.toIso8601String(),
      };

      final response = await dio.post('/bookings', data: data);

      // Get the created booking ID for image uploads
      if (response.data != null && response.data['_id'] != null) {
        setState(() {
          _bookingId = response.data['_id'];
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking added successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      print("❌ Error adding booking: $e");
      print(stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add booking: $e')),
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
    String? Function(String?)? validator,
  }) {
    final isMultiline = maxLines == null || (maxLines > 1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
        maxLines: maxLines,
        minLines: minLines,
        validator: validator,
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
          title: const Text('Add Booking'),
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
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
            _buildCard(
              title: "Guest Information",
              children: [
                _buildTextField(
                  label: 'Guest Name *',
                  controller: _guestNameController,
                  validator: (v) => v!.isEmpty ? 'Enter guest name' : null,
                ),
                _buildTextField(
                  label: 'NIC (Optional)',
                  controller: _guestNicController,
                ),
                _buildTextField(
                  label: 'Phone Number *',
                  controller: _phoneNoController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Enter phone number' : null,
                ),
                _buildTextField(
                  label: 'Address (Optional)',
                  controller: _guestAddressController,
                  maxLines: null,
                  minLines: 2,
                ),
              ],
            ),

            _buildCard(
              title: "Booking Details",
              children: [
                _buildDateSelector(
                  label: 'Check-in Date *',
                  selectedDate: _checkinDate,
                  onTap: () => _pickDate(context, true),
                  icon: Icons.login,
                ),
                _buildDateSelector(
                  label: 'Check-out Date *',
                  selectedDate: _checkoutDate,
                  onTap: () => _pickDate(context, false),
                  icon: Icons.logout,
                ),
                RoomSelectorWidget(
                  selectedRooms: _selectedRooms,
                  checkinDate: _checkinDate,
                  checkoutDate: _checkoutDate,
                  onRoomToggle: _handleRoomToggle,
                ),
                _buildDateSelector(
                  label: 'Birthday (Optional)',
                  selectedDate: _birthday,
                  onTap: () => _pickBirthday(context),
                  icon: Icons.cake,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Adults *',
                        controller: _adultCountController,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Children',
                        controller: _childCountController,
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
                  controller: _totalPriceController,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Advance Amount (LKR)',
                  controller: _advanceAmountController,
                  keyboardType: TextInputType.number,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _status,
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
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Row(
                          children: [
                            Icon(Icons.pending, color: Colors.orange, size: 20),
                            SizedBox(width: 12),
                            Text('Pending'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'advance_paid',
                        child: Row(
                          children: [
                            Icon(Icons.payments, color: Colors.blue, size: 20),
                            SizedBox(width: 12),
                            Text('Advance Paid'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'paid',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 12),
                            Text('Paid'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Text('Cancelled'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _status = value.toString();
                      });
                    },
                  ),
                ),
              ],
            ),

            _buildCard(
              title: "Additional Notes",
              children: [
                _buildTextField(
                  label: 'Special Notes (Optional)',
                  controller: _specialNotesController,
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
                  entityId: _bookingId,
                  onNICDataSelected: _handleNICDataSelected,
                ),
              ],
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addBooking,
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
                'Add Booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _guestNicController.dispose();
    _guestNameController.dispose();
    _phoneNoController.dispose();
    _adultCountController.dispose();
    _childCountController.dispose();
    _guestAddressController.dispose();
    _totalPriceController.dispose();
    _specialNotesController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }
}
