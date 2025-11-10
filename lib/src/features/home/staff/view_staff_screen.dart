import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/common_image_manager.dart';
import '../../../core/utils/decimal_helper.dart';
import 'edit_staff_screen.dart';

class ViewStaffScreen extends ConsumerWidget {
  final Map<String, dynamic> staff;

  const ViewStaffScreen({super.key, required this.staff});

  // Helper method to safely format salary
  String _formatSalary(dynamic salary) {
    if (salary == null) return 'N/A';

    try {
      // Handle Decimal128 format from MongoDB
      if (salary is Map && salary.containsKey('\$numberDecimal')) {
        final value = double.tryParse(salary['\$numberDecimal'].toString()) ?? 0.0;
        return '\${value.toStringAsFixed(2)}';
      }

      // Handle regular number
      if (salary is num) {
        return '\${salary.toStringAsFixed(2)}';
      }

      // Handle string
      if (salary is String) {
        final value = double.tryParse(salary) ?? 0.0;
        return '\${value.toStringAsFixed(2)}';
      }

      return '\${salary.toString()}';
    } catch (e) {
      print('Error formatting salary: $e');
      return 'N/A';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'owner':
        return Colors.red;
      case 'manager':
        return Colors.blue;
      case 'technician':
        return Colors.orange;
      case 'reception':
        return Colors.green;
      case 'cleaning':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffId = staff['_id'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditStaffScreen(staff: staff),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: staff['profile_picture'] != null
                          ? NetworkImage(staff['profile_picture'])
                          : null,
                      child: staff['profile_picture'] == null
                          ? Icon(Icons.person, size: 60, color: Colors.blue.shade700)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      staff['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(staff['role']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getRoleColor(staff['role']),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        staff['role'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getRoleColor(staff['role']),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Contact Information
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.contact_mail, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (staff['email'] != null) ...[
                      _buildInfoRow(
                        Icons.email,
                        'Email',
                        staff['email'],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (staff['phone'] != null)
                      _buildInfoRow(
                        Icons.phone,
                        'Phone',
                        staff['phone'],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Personal Information
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (staff['birthday'] != null) ...[
                      _buildInfoRow(
                        Icons.cake,
                        'Birthday',
                        DateFormat('MMMM d, yyyy').format(
                          DateTime.parse(staff['birthday']),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (staff['joined_date'] != null)
                      _buildInfoRow(
                        Icons.date_range,
                        'Joined Date',
                        DateFormat('MMMM d, yyyy').format(
                          DateTime.parse(staff['joined_date']),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Employment Information
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.work_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Employment Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (staff['current_salary'] != null)
                      _buildInfoRow(
                        Icons.attach_money,
                        'Current Salary',
                        _formatSalary(staff['current_salary']),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Documents Section
            if (staffId.isNotEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder_outlined, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Documents',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      CommonImageManager(
                        entityType: 'Staff',
                        entityId: staffId,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}