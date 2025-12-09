import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';

class AddHotelScreen extends ConsumerStatefulWidget {
  const AddHotelScreen({super.key});

  @override
  ConsumerState<AddHotelScreen> createState() => _AddHotelScreenState();
}

class _AddHotelScreenState extends ConsumerState<AddHotelScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addHotel() async {
    if (_formKey.currentState!.validate()) {
      final dio = ref.read(dioProvider);

      try {
        await dio.post('/hotels', data: {
          'name': _nameController.text.trim(),
          'location': {
            'city': _cityController.text.trim(),
            'address': _addressController.text.trim(),
          },
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': 0,
          'status': 'available',
        });

        if (context.mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add hotel: $e')),
          );
        }
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text, bool required = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        minLines: maxLines > 1 ? 3 : 1, // Ensures multiline fields start with visible lines
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1, // Aligns label to top for multiline
        ),
        validator: required ? (value) => value!.isEmpty ? 'Enter $label' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Hotel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Hotel Name", _nameController),
              _buildTextField("City", _cityController),
              _buildTextField("Phone Number", _phoneController, inputType: TextInputType.phone),
              _buildTextField("Address (Optional)", _addressController, required: false),
              _buildTextField("Email (Optional)", _emailController, inputType: TextInputType.emailAddress, required: false),
              _buildTextField("Description (Optional)", _descriptionController,
                  maxLines: 5, // Increased to 5 lines for better visibility
                  inputType: TextInputType.multiline, // Better keyboard for multiline
                  required: false),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addHotel,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Add Hotel',
                    style: TextStyle(fontSize: 16),
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