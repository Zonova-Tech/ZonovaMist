// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart';

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

  bool _loading = false;

  // Supported placeholders for validation
  final List<String> _validPlaceholders = [
    '{clientName}',
    '{roomNo}',
    '{checkInDate}',
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
      _newBookingSmsController.text = (

          data['newBookingSmsTemplate'] ?? '').toString();
      _todayBookingSmsController.text = (data['todayBookingSmsTemplate'] ?? '').toString();
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
  String? _validateSmsTemplate(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final invalidPlaceholders = RegExp(r'\{[^}]*\}')
        .allMatches(value)
        .map((m) => m.group(0))
        .where((p) => !_validPlaceholders.contains(p))
        .toList();
    if (invalidPlaceholders.isNotEmpty) {
      return 'Invalid placeholders: ${invalidPlaceholders.join(', ')}. Use {checkInDate} instead of {date}.';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _guestHouseNameController,
                decoration: const InputDecoration(labelText: 'Guest House Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _guestHouseAddressController,
                decoration: const InputDecoration(labelText: 'Guest House Address'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hostNameController,
                decoration: const InputDecoration(labelText: 'Host Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: 'Telephone'),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newBookingSmsController,
                decoration: const InputDecoration(
                  labelText: 'New Booking SMS Template',
                  hintText: 'e.g., Hello {clientName}, your booking for room {roomNo} is confirmed for {checkInDate}.',
                ),
                maxLines: 3,
                validator: _validateSmsTemplate,
              ),
              const SizedBox(height: 6),
              Text(
                'Valid placeholders: ${_validPlaceholders.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _todayBookingSmsController,
                decoration: const InputDecoration(
                  labelText: 'Today Booking SMS Template',
                  hintText: 'e.g., Hello {clientName}, reminder: check-in today for room {roomNo} at {guestHouseName}.',
                ),
                maxLines: 3,
                validator: _validateSmsTemplate,
              ),
              const SizedBox(height: 6),
              Text(
                'Valid placeholders: ${_validPlaceholders.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}