import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_service.dart';
import '../../../shared/widgets/common_image_manager.dart';
import '../../../shared/widgets/profile_picture_uploader.dart';
import '../../../core/utils/decimal_helper.dart';
import 'staff_provider.dart';

class EditStaffScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> staff;
  const EditStaffScreen({super.key, required this.staff});

  @override
  ConsumerState<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends ConsumerState<EditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _salaryController;
  DateTime? _birthday;
  DateTime? _joinedDate;
  String? _selectedRole;
  String? _profilePictureUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff['name']);
    _emailController = TextEditingController(text: widget.staff['email']);
    _phoneController = TextEditingController(text: widget.staff['phone']);
    // Use helper to handle Decimal128 format
    _salaryController = TextEditingController(
      text: DecimalHelper.toEditableString(widget.staff['current_salary']),
    );
    if (widget.staff['birthday'] != null) {
      _birthday = DateTime.parse(widget.staff['birthday']);
    }
    if (widget.staff['joined_date'] != null) {
      _joinedDate = DateTime.parse(widget.staff['joined_date']);
    }
    _selectedRole = widget.staff['role'];
    _profilePictureUrl = widget.staff['profile_picture'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isBirthday) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBirthday ? (_birthday ?? DateTime.now()) : (_joinedDate ?? DateTime.now()),
      firstDate: isBirthday ? DateTime(1950) : DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isBirthday) {
          _birthday = picked;
        } else {
          _joinedDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/staff/${widget.staff['_id']}', data: {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'birthday': _birthday?.toIso8601String(),
        'joined_date': _joinedDate?.toIso8601String(),
        'current_salary': _salaryController.text.isNotEmpty ? double.tryParse(_salaryController.text) : null,
        'role': _selectedRole,
        'profile_picture': _profilePictureUrl, // ✅ Save profile picture URL
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff member updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update staff: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(staffRolesProvider);
    final staffId = widget.staff['_id'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Staff Member'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture with Uploader
              Center(
                child: ProfilePictureUploader(
                  entityType: 'Staff',
                  entityId: staffId,
                  currentImageUrl: _profilePictureUrl,
                  size: 100,
                  onImageUpdated: (url) {
                    setState(() {
                      _profilePictureUrl = url;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Birthday
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Birthday',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _birthday != null ? DateFormat('yyyy-MM-dd').format(_birthday!) : 'Select birthday',
                    style: TextStyle(
                      color: _birthday != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Joined Date
              InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Joined Date',
                    prefixIcon: Icon(Icons.date_range),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _joinedDate != null ? DateFormat('yyyy-MM-dd').format(_joinedDate!) : 'Select joined date',
                    style: TextStyle(
                      color: _joinedDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Current Salary
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Current Salary',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Role Dropdown
              rolesAsync.when(
                data: (roles) => DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(),
                  ),
                  items: roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedRole = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a role';
                    }
                    return null;
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading roles: $err'),
              ),
              const SizedBox(height: 24),

              // Document Upload Section
              if (staffId.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.file_upload, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Documents (NIC, etc.)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CommonImageManager(
                          entityType: 'Staff',
                          entityId: staffId,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Update Staff Member'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
