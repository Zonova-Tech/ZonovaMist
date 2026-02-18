import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/rbac.dart';
import '../../../shared/widgets/common_image_manager.dart';
import '../../../core/utils/decimal_helper.dart';
import 'edit_staff_screen.dart';
import 'staff_provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_state.dart';
import '../../../shared/widgets/rbac_gate.dart';

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
        return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
      }

      // Handle regular number
      if (salary is num) {
        return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(salary);
      }

      // Handle string
      if (salary is String) {
        final value = double.tryParse(salary) ?? 0.0;
        return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
      }

      return 'N/A';
    } catch (e) {
      print('Error formatting salary: $e');
      print('Salary value: $salary');
      print('Salary type: ${salary.runtimeType}');
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

    return RbacGate(
      permission: AppPermission.staff,
      child: Scaffold(
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

            // Performance & Reviews Section
            Consumer(
              builder: (context, ref, child) {
                final performanceAsync = ref.watch(staffPerformanceProvider(staffId));

                return performanceAsync.when(
                  data: (data) {
                    final double avgRating = (data['averageRating'] ?? 0).toDouble();
                    final int totalRatings = data['totalRatings'] ?? 0;
                    final int tasksCompleted = data['totalTasksCompleted'] ?? 0;
                    final List reviews = data['recentReviews'] ?? [];

                    return Card(
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
                                Icon(Icons.star_outline, color: Colors.amber.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Performance & Reviews',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            
                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const Text('Avg Rating', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      totalRatings.toString(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text('Reviews', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      tasksCompleted.toString(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const Text('Completed', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            
                            if (reviews.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              const Text(
                                'Recent Feedback',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reviews.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final review = reviews[index];
                                  final rating = review['rating'] ?? 0;
                                  final comment = review['ratingComment'] ?? '';
                                  final ratedByName = review['ratedBy']?['fullName'] ?? 'Unknown';
                                  final date = review['ratedAt'] != null 
                                      ? DateFormat('MMM d, y').format(DateTime.parse(review['ratedAt'])) 
                                      : 'Unknown date';
                                  final taskTitle = review['title'] ?? 'Task';

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ...List.generate(5, (i) => Icon(
                                            i < rating ? Icons.star : Icons.star_border,
                                            size: 14,
                                            color: Colors.amber,
                                          )),
                                          const SizedBox(width: 8),
                                          Text(
                                            date,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment,
                                        style: const TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'by $ratedByName • $taskTitle',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ] else if (tasksCompleted > 0) ...[
                               const SizedBox(height: 16),
                               const Padding(
                                 padding: EdgeInsets.all(8.0),
                                 child: Center(
                                   child: Text(
                                     'No written reviews yet.',
                                     style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                   ),
                                 ),
                               ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )),
                  error: (err, stack) => const SizedBox.shrink(), // Hide on error
                );
              },
            ),
            const SizedBox(height: 16),

            // Employment Information - Only visible to Admin/Manager
            Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authProvider);
                final isPrivileged = (authState is Authenticated) && 
                    ['admin', 'manager', 'owner'].contains(authState.role.toLowerCase());

                if (!isPrivileged) return const SizedBox.shrink();

                if (staff['current_salary'] == null) return const SizedBox.shrink();

                return Card(
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
                        _buildInfoRow(
                          Icons.attach_money,
                          'Current Salary',
                          _formatSalary(staff['current_salary']),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
