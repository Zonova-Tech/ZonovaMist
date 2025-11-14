// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart';
import '../../../shared/widgets/app_drawer.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _guestHouseNameController = TextEditingController();
  final _guestHouseAddressController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _newBookingSmsController = TextEditingController();
  final _todayBookingSmsController = TextEditingController();
  final _advancePaidSmsController = TextEditingController();
  final _discountSmsController = TextEditingController();
  final _guestHouseLocationController = TextEditingController();
  final _discountAmountController = TextEditingController();
  final _validityPeriodController = TextEditingController();
  final _daysAfterCheckoutController = TextEditingController();

  bool _loading = false;

  // Supported placeholders for validation
  final List<String> _validPlaceholders = [
    '{clientName}',
    '{roomNo}',
    '{checkInDate}',
    '{guestHouseName}',
    '{hostName}',
  ];

  // Additional placeholders for advance paid SMS
  final List<String> _advancePaidPlaceholders = [
    '{clientName}',
    '{roomNo}',
    '{advanceAmount}',
    '{invoiceLink}',
    '{guestHouseName}',
    '{hostName}',
  ];

  // Placeholders for discount SMS
  final List<String> _discountPlaceholders = [
    '{clientName}',
    '{location}',
    '{guestHouseName}',
    '{validityPeriod}',
    '{discountAmount}',
    '{telephone}',
  ];

  Future<void> _loadSettings() async {
    try {
      setState(() => _loading = true);
      final dio = ref.read(dioProvider);
      final response = await dio.get('/settings');
      final data = response.data;

      print('📥 Settings JSON: $data');

      _guestHouseNameController.text = (data['guestHouseName'] ?? '').toString();
      _guestHouseAddressController.text = (data['guestHouseAddress'] ?? '').toString();
      _hostNameController.text = (data['hostName'] ?? '').toString();
      _telephoneController.text = (data['telephone'] ?? '94728651815').toString();
      _newBookingSmsController.text = (data['newBookingSmsTemplate'] ?? '').toString();
      _todayBookingSmsController.text = (data['todayBookingSmsTemplate'] ?? '').toString();
      _advancePaidSmsController.text = (data['advancePaidSmsTemplate'] ??
          'Dear {clientName}, advance payment of Rs. {advanceAmount} received for Room {roomNo}. View invoice: {invoiceLink} - {guestHouseName}').toString();
      _discountSmsController.text = (data['discountSmsTemplate'] ??
          'Missing the cool breeze of {location}? Stay at {guestHouseName} again {validityPeriod} and enjoy LKR {discountAmount} off per night. Call or WhatsApp us at {telephone}').toString();
      _guestHouseLocationController.text = (data['guestHouseLocation'] ?? 'Ambewela').toString();
      _discountAmountController.text = (data['discountAmount'] ?? 4000).toString();
      _validityPeriodController.text = (data['discountValidityPeriod'] ?? 'within a month').toString();
      _daysAfterCheckoutController.text = (data['discountSmsDaysAfterCheckout'] ?? 10).toString();
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _loading = true);
      final dio = ref.read(dioProvider);
      await dio.post('/settings', data: {
        'guestHouseName': _guestHouseNameController.text,
        'guestHouseAddress': _guestHouseAddressController.text,
        'hostName': _hostNameController.text,
        'telephone': _telephoneController.text,
        'newBookingSmsTemplate': _newBookingSmsController.text,
        'todayBookingSmsTemplate': _todayBookingSmsController.text,
        'advancePaidSmsTemplate': _advancePaidSmsController.text,
        'discountSmsTemplate': _discountSmsController.text,
        'guestHouseLocation': _guestHouseLocationController.text,
        'discountAmount': int.tryParse(_discountAmountController.text) ?? 4000,
        'discountValidityPeriod': _validityPeriodController.text,
        'discountSmsDaysAfterCheckout': int.tryParse(_daysAfterCheckoutController.text) ?? 10,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Settings saved successfully')),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  // Validate SMS templates for placeholders
  String? _validateSmsTemplate(String? value, {List<String>? validPlaceholders}) {
    if (value == null || value.isEmpty) return 'Required';

    final placeholders = validPlaceholders ?? _validPlaceholders;

    final invalidPlaceholders = RegExp(r'\{[^}]*\}')
        .allMatches(value)
        .map((m) => m.group(0))
        .where((p) => !placeholders.contains(p))
        .toList();

    if (invalidPlaceholders.isNotEmpty) {
      return 'Invalid placeholders: ${invalidPlaceholders.join(', ')}';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _guestHouseNameController.dispose();
    _guestHouseAddressController.dispose();
    _hostNameController.dispose();
    _telephoneController.dispose();
    _newBookingSmsController.dispose();
    _todayBookingSmsController.dispose();
    _advancePaidSmsController.dispose();
    _discountSmsController.dispose();
    _guestHouseLocationController.dispose();
    _discountAmountController.dispose();
    _validityPeriodController.dispose();
    _daysAfterCheckoutController.dispose();
    super.dispose();
  }

  Widget _buildCard({required String title, String? subtitle, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                title: 'Guest House Information',
                children: [
                  TextFormField(
                    controller: _guestHouseNameController,
                    decoration: const InputDecoration(
                      labelText: 'Guest House Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _guestHouseAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Guest House Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _guestHouseLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Location (e.g., Ambewela)',
                      border: OutlineInputBorder(),
                      helperText: 'Used in discount SMS',
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hostNameController,
                    decoration: const InputDecoration(
                      labelText: 'Host Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telephoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telephone',
                      border: OutlineInputBorder(),
                      helperText: 'Include country code (e.g., 94728651815)',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),

              _buildCard(
                title: 'SMS Templates',
                children: [
                  // New Booking SMS Template
                  TextFormField(
                    controller: _newBookingSmsController,
                    decoration: const InputDecoration(
                      labelText: 'New Booking SMS Template',
                      hintText: 'Hello {clientName}, your booking for room {roomNo}...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) => _validateSmsTemplate(v),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Valid placeholders: ${_validPlaceholders.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Today Booking SMS Template
                  TextFormField(
                    controller: _todayBookingSmsController,
                    decoration: const InputDecoration(
                      labelText: 'Today Booking Reminder SMS Template',
                      hintText: 'Hello {clientName}, reminder: check-in today...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) => _validateSmsTemplate(v),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Valid placeholders: ${_validPlaceholders.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Advance Paid SMS Template
                  TextFormField(
                    controller: _advancePaidSmsController,
                    decoration: const InputDecoration(
                      labelText: 'Advance Paid Invoice SMS Template',
                      hintText: 'Dear {clientName}, advance payment of Rs. {advanceAmount}...',
                      border: OutlineInputBorder(),
                      helperText: 'Sent when booking status changes to Advance Paid',
                      helperMaxLines: 2,
                    ),
                    maxLines: 4,
                    validator: (v) => _validateSmsTemplate(v, validPlaceholders: _advancePaidPlaceholders),
                  ),
                  const SizedBox(height: 6),
                  _buildPlaceholderInfo(
                    'Advance Paid SMS Placeholders',
                    _advancePaidPlaceholders,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),

                  // NEW: Discount SMS Template
                  TextFormField(
                    controller: _discountSmsController,
                    decoration: const InputDecoration(
                      labelText: 'Discount SMS Template',
                      hintText: 'Missing the cool breeze of {location}?...',
                      border: OutlineInputBorder(),
                      helperText: 'Sent automatically after specified days from checkout',
                      helperMaxLines: 2,
                    ),
                    maxLines: 4,
                    validator: (v) => _validateSmsTemplate(v, validPlaceholders: _discountPlaceholders),
                  ),
                  const SizedBox(height: 6),
                  _buildPlaceholderInfo(
                    'Discount SMS Placeholders',
                    _discountPlaceholders,
                    Colors.green,
                  ),
                ],
              ),

              _buildCard(
                title: 'Discount SMS Configuration',
                subtitle: 'Automatic SMS sent to guests after checkout',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _discountAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Discount Amount (LKR)',
                            border: OutlineInputBorder(),
                            prefixText: 'Rs. ',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _daysAfterCheckoutController,
                          decoration: const InputDecoration(
                            labelText: 'Days After Checkout',
                            border: OutlineInputBorder(),
                            suffixText: 'days',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _validityPeriodController,
                    decoration: const InputDecoration(
                      labelText: 'Validity Period Text',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., within a month, within 30 days',
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SMS will be sent automatically every day at 9:00 AM to eligible guests',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderInfo(String title, List<String> placeholders, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color[900],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            placeholders.join(', '),
            style: TextStyle(
              color: color[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}