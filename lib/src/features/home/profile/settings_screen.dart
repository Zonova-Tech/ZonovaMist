import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart'; // <- your dioProvider

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

  Future<void> _loadSettings() async {
    try {
      setState(() => _loading = true);
      final dio = ref.read(dioProvider); // ✅ use configured dio
      final response = await dio.get("/settings");
      final data = response.data;

      print("📥 Settings JSON: $data");

      _guestHouseNameController.text = (data['guestHouseName'] ?? '').toString();
      _guestHouseAddressController.text = (data['guestHouseAddress'] ?? '').toString();
      _hostNameController.text = (data['hostName'] ?? '').toString();
      _telephoneController.text = (data['telephone'] ?? '').toString();
      _newBookingSmsController.text = (data['newBookingSmsTemplate'] ?? '').toString();
      _todayBookingSmsController.text = (data['todayBookingSmsTemplate'] ?? '').toString();
    } catch (e) {
      debugPrint("❌ Error loading settings: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _loading = true);
      final dio = ref.read(dioProvider); // ✅ use configured dio
      await dio.post("/settings", data: {
        "guestHouseName": _guestHouseNameController.text,
        "guestHouseAddress": _guestHouseAddressController.text,
        "hostName": _hostNameController.text,
        "telephone": _telephoneController.text,
        "newBookingSmsTemplate": _newBookingSmsController.text,
        "todayBookingSmsTemplate": _todayBookingSmsController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Settings saved successfully")),
        );
      }
    } catch (e) {
      debugPrint("❌ Error saving settings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save settings")),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _guestHouseNameController,
                decoration: const InputDecoration(labelText: "Guest House Name"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _guestHouseAddressController,
                decoration: const InputDecoration(labelText: "Guest House Address"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _hostNameController,
                decoration: const InputDecoration(labelText: "Host Name"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: "Telephone"),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _newBookingSmsController,
                decoration: const InputDecoration(labelText: "New Booking SMS Template"),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _todayBookingSmsController,
                decoration: const InputDecoration(labelText: "Today Booking SMS Template"),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
