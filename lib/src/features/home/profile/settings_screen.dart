import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart'; // your dioProvider

// 1️⃣ Define enum for templates
enum TemplateType {
  newBookingConfirmation,
  todayBookingReminder,
}

// 2️⃣ Map enum to display names
const Map<TemplateType, String> templateDisplayNames = {
  TemplateType.newBookingConfirmation: "New Booking Confirmation",
  TemplateType.todayBookingReminder: "Today Booking Reminder",
};

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

  // SMS template
  TemplateType? _selectedTemplate;
  final TextEditingController _greetingController =
  TextEditingController(text: "Hello");
  final TextEditingController _customTextController =
  TextEditingController(text: "your booking is confirmed");
  final TextEditingController _endingController =
  TextEditingController(text: "Have a nice day!");

  // Saved templates
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
      if (_selectedTemplate == TemplateType.newBookingConfirmation) {
        _previewMessage =
        "Hello, {clientName} your booking is confirmed for room {roomNo} on {date}. Have a nice day!";
      } else if (_selectedTemplate == TemplateType.todayBookingReminder) {
        _previewMessage =
        "Hello, {clientName} just a reminder of your booking today in room {roomNo}. Have a nice day!";
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

      // Set default selected template
      if (_newBookingTemplate != null && _newBookingTemplate!.isNotEmpty) {
        _selectedTemplate = TemplateType.newBookingConfirmation;
        _customTextController.text = _newBookingTemplate!
            .replaceAll("{clientName}", "")
            .replaceAll("{roomNo}", "")
            .replaceAll("{date}", "")
            .trim();
      } else if (_todayBookingTemplate != null &&
          _todayBookingTemplate!.isNotEmpty) {
        _selectedTemplate = TemplateType.todayBookingReminder;
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

    // SMS validation
    if (_greetingController.text.trim().isEmpty ||
        _customTextController.text.trim().isEmpty ||
        _endingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All SMS fields are required")),
      );
      return;
    }

    try {
      setState(() => _loading = true);
      final dio = ref.read(dioProvider);

      final Map<String, dynamic> data = {
        "guestHouseName": _guestHouseNameController.text.trim(),
        "guestHouseAddress": _guestHouseAddressController.text.trim(),
        "hostName": _hostNameController.text.trim(),
        "telephone": _telephoneController.text.trim(),
      };

      // Save the selected template
      if (_selectedTemplate == TemplateType.newBookingConfirmation) {
        data["newBookingSmsTemplate"] = _previewMessage;
      } else if (_selectedTemplate == TemplateType.todayBookingReminder) {
        data["todayBookingSmsTemplate"] = _previewMessage;
      }

      print("📤 Saving settings with data: $data");

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
                validator: (val) =>
                val == null || val.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _guestHouseAddressController,
                decoration: const InputDecoration(
                    labelText: "Guest House Address"),
                validator: (val) =>
                val == null || val.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _hostNameController,
                decoration:
                const InputDecoration(labelText: "Host Name"),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  if (!RegExp(r"^[a-zA-Z ]+$").hasMatch(val)) {
                    return "Invalid name";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _telephoneController,
                decoration:
                const InputDecoration(labelText: "Telephone"),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  if (!RegExp(r"^\d{10,11}$").hasMatch(val)) {
                    return "Invalid phone number";
                  }
                  return null;
                },
              ),

              const Divider(height: 40),

              // SMS template section
              DropdownButtonFormField<TemplateType>(
                decoration:
                const InputDecoration(labelText: "Select Template"),
                value: _selectedTemplate,
                items: TemplateType.values.map((template) {
                  return DropdownMenuItem(
                    value: template,
                    child: Text(templateDisplayNames[template]!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTemplate = value);

                  if (value == TemplateType.newBookingConfirmation &&
                      _newBookingTemplate != null) {
                    _customTextController.text = _newBookingTemplate!
                        .replaceAll("{clientName}", "")
                        .replaceAll("{roomNo}", "")
                        .replaceAll("{date}", "")
                        .trim();
                  } else if (value ==
                      TemplateType.todayBookingReminder &&
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
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: "Custom Text",
                  counterText: "",
                ),
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
