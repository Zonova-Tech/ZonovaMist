import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/todo_model.dart';

class TodoDetailsDialog extends StatelessWidget {
  final Todo todo;

  const TodoDetailsDialog({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Task Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Title
              _buildDetailRow(
                'Title',
                todo.title,
                Icons.title,
                Colors.blue,
              ),

              // Description
              if (todo.description.isNotEmpty)
                _buildDetailRow(
                  'Description',
                  todo.description,
                  Icons.description,
                  Colors.green,
                ),

              // Due Date
              _buildDetailRow(
                'Due Date',
                DateFormat('MMMM dd, yyyy').format(todo.dueDate),
                Icons.calendar_today,
                todo.isOverdue ? Colors.red : Colors.orange,
              ),

              // Priority
              _buildDetailRow(
                'Priority',
                todo.priority,
                Icons.flag,
                _getPriorityColor(todo.priority),
              ),

              // Status
              _buildDetailRow(
                'Status',
                todo.status,
                Icons.info,
                _getStatusColor(todo.status),
              ),

              // Assigned To
              if (todo.assignedToName != null)
                _buildDetailRow(
                  'Assigned To',
                  '${todo.assignedToName} (${todo.assignedToEmail})',
                  Icons.person,
                  Colors.purple,
                ),

              // Created By
              if (todo.createdByName != null)
                _buildDetailRow(
                  'Created By',
                  '${todo.createdByName} (${todo.createdByEmail})',
                  Icons.person_outline,
                  Colors.indigo,
                ),

              // Created Date
              _buildDetailRow(
                'Created',
                DateFormat('MMMM dd, yyyy').format(todo.createdDate),
                Icons.access_time,
                Colors.grey,
              ),

              // Images
              if (todo.images.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Attached Images',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: todo.images.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            todo.images[index].url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Approved':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}