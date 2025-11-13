// settings_screen.dart
import 'package:flutter/material.dart';
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
      _telephoneController.text = (data['telephone'] ?? '').toString();
      _newBookingSmsController.text = (data['newBookingSmsTemplate'] ?? '').toString();
      _todayBookingSmsController.text = (data['todayBookingSmsTemplate'] ?? '').toString();
      _advancePaidSmsController.text = (data['advancePaidSmsTemplate'] ??
          'Dear {clientName}, advance payment of Rs. {advanceAmount} received for Room {roomNo}. View invoice: {invoiceLink} - {guestHouseName}').toString();
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
  String? _validateSmsTemplate(String? value, {bool isAdvancePaid = false}) {
    if (value == null || value.isEmpty) return 'Required';

    final validPlaceholders = isAdvancePaid ? _advancePaidPlaceholders : _validPlaceholders;

    final invalidPlaceholders = RegExp(r'\{[^}]*\}')
        .allMatches(value)
        .map((m) => m.group(0))
        .where((p) => !validPlaceholders.contains(p))
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
    super.dispose();
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
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
                      hintText: 'e.g., Hello {clientName}, your booking for room {roomNo} is confirmed...',
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
                      hintText: 'e.g., Hello {clientName}, reminder: check-in today for room {roomNo}...',
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

                  // NEW: Advance Paid SMS Template
                  TextFormField(
                    controller: _advancePaidSmsController,
                    decoration: const InputDecoration(
                      labelText: 'Advance Paid Invoice SMS Template',
                      hintText: 'Dear {clientName}, advance payment of Rs. {advanceAmount} received...',
                      border: OutlineInputBorder(),
                      helperText: 'This SMS is sent when booking status changes to Advance Paid',
                      helperMaxLines: 2,
                    ),
                    maxLines: 4,
                    validator: (v) => _validateSmsTemplate(v, isAdvancePaid: true),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valid placeholders for Advance Paid SMS:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _advancePaidPlaceholders.join(', '),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '⚠️ Important: {invoiceLink} will be automatically generated and included',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
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
            ],
          ),
        ),
      ),
    );
  }
}