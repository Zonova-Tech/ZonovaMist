import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart'; // your dioProvider

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Guest house controllers
  final _guestHouseNameController = TextEditingController();
  final _guestHouseAddressController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _telephoneController = TextEditingController();

  // SMS template controllers
  String? _selectedTemplate;
  final List<String> _templates = [
    "New Booking Confirmation",
    "Today Booking Reminder"
  ];

  final TextEditingController _greetingController =
  TextEditingController(text: "Hello");
  final TextEditingController _customTextController =
  TextEditingController(text: "your booking is confirmed");
  final TextEditingController _endingController =
  TextEditingController(text: "Have a nice day!");

  String? _newBookingTemplate;
  String? _todayBookingTemplate;

  String _previewMessage = "";

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _updatePreview() {
    setState(() {
      if (_selectedTemplate == "New Booking Confirmation") {
        _previewMessage =
        "${_greetingController.text} {clientName}, ${_customTextController.text} for room {roomNo} on {date}. ${_endingController.text}";
      } else if (_selectedTemplate == "Today Booking Reminder") {
        _previewMessage =
        "${_greetingController.text} {clientName}, just a reminder of your booking today in room {roomNo}. ${_endingController.text}";
      } else {
        _previewMessage = "";
      }
    });
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _loading = true);
      final dio = ref.read(dioProvider);
      final response = await dio.get("/settings");
      final data = response.data;

      print("📥 Settings JSON: $data");

      _guestHouseNameController.text = (data['guestHouseName'] ?? '').toString();
      _guestHouseAddressController.text =
          (data['guestHouseAddress'] ?? '').toString();
      _hostNameController.text = (data['hostName'] ?? '').toString();
      _telephoneController.text = (data['telephone'] ?? '').toString();

      // Load SMS templates
      _newBookingTemplate = data['newBookingSmsTemplate']?.toString();
      _todayBookingTemplate = data['todayBookingSmsTemplate']?.toString();

      // Set default selected template if available
      if (_newBookingTemplate != null && _newBookingTemplate!.isNotEmpty) {
        _selectedTemplate = "New Booking Confirmation";
        _customTextController.text = _newBookingTemplate!
            .replaceAll("{clientName}", "")
            .replaceAll("{roomNo}", "")
            .replaceAll("{date}", "")
            .trim();
      } else if (_todayBookingTemplate != null &&
          _todayBookingTemplate!.isNotEmpty) {
        _selectedTemplate = "Today Booking Reminder";
        _customTextController.text = _todayBookingTemplate!
            .replaceAll("{clientName}", "")
            .replaceAll("{roomNo}", "")
            .replaceAll("{date}", "")
            .trim();
      }

      _updatePreview();
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
      final dio = ref.read(dioProvider);

      // Prepare request data
      final Map<String, dynamic> data = {
        "guestHouseName": _guestHouseNameController.text,
        "guestHouseAddress": _guestHouseAddressController.text,
        "hostName": _hostNameController.text,
        "telephone": _telephoneController.text,
      };

      // Add only the selected SMS template
      if (_selectedTemplate == "New Booking Confirmation") {
        data["newBookingSmsTemplate"] = _previewMessage;
      } else if (_selectedTemplate == "Today Booking Reminder") {
        data["todayBookingSmsTemplate"] = _previewMessage;
      }

      print("📤 Saving settings with data: $data"); // Debug print

      await dio.post("/settings", data: data);

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
              // Guest house info
              TextFormField(
                controller: _guestHouseNameController,
                decoration:
                const InputDecoration(labelText: "Guest House Name"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _guestHouseAddressController,
                decoration: const InputDecoration(
                    labelText: "Guest House Address"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _hostNameController,
                decoration:
                const InputDecoration(labelText: "Host Name"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _telephoneController,
                decoration:
                const InputDecoration(labelText: "Telephone"),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),

              const Divider(height: 40),

              // SMS template section
              DropdownButtonFormField<String>(
                decoration:
                const InputDecoration(labelText: "Select Template"),
                value: _selectedTemplate,
                items: _templates
                    .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedTemplate = value);

                  // Load the saved template text if available
                  if (value == "New Booking Confirmation" &&
                      _newBookingTemplate != null) {
                    _customTextController.text = _newBookingTemplate!
                        .replaceAll("{clientName}", "")
                        .replaceAll("{roomNo}", "")
                        .replaceAll("{date}", "")
                        .trim();
                  } else if (value == "Today Booking Reminder" &&
                      _todayBookingTemplate != null) {
                    _customTextController.text = _todayBookingTemplate!
                        .replaceAll("{clientName}", "")
                        .replaceAll("{roomNo}", "")
                        .replaceAll("{date}", "")
                        .trim();
                  }

                  _updatePreview();
                },
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _greetingController,
                decoration:
                const InputDecoration(labelText: "Greeting"),
                onChanged: (_) => _updatePreview(),
              ),
              TextField(
                controller: _customTextController,
                decoration:
                const InputDecoration(labelText: "Custom Text"),
                onChanged: (_) => _updatePreview(),
              ),
              TextField(
                controller: _endingController,
                decoration: const InputDecoration(labelText: "Ending"),
                onChanged: (_) => _updatePreview(),
              ),

              const SizedBox(height: 20),

              const Text("📩 Message Preview:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _previewMessage,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.black87),
                ),
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
