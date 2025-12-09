import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'providers/todo_provider.dart';
import 'models/todo_model.dart';
import 'add_todo_screen.dart';
import 'todo_details_dialog.dart';

class TasksView extends ConsumerStatefulWidget {
  const TasksView({super.key});

  @override
  ConsumerState<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends ConsumerState<TasksView> {
  String _filterStatus = 'All';
  String _filterPriority = 'All';

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoProvider);

    return Column(
      children: [
        // Filter Section
        _buildFilterSection(),

        // Todo List
        Expanded(
          child: todoState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : todoState.error != null
              ? _buildErrorWidget(todoState.error!)
              : _buildTodoList(todoState.todos),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _filterStatus = 'All';
                    _filterPriority = 'All';
                  });
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Status', _filterStatus, [
                  'All', 'New', 'Completed', 'Approved'
                ], (value) {
                  setState(() => _filterStatus = value);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Priority', _filterPriority, [
                  'All', 'High', 'Medium', 'Low'
                ], (value) {
                  setState(() => _filterPriority = value);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label,
      String currentValue,
      List<String> options,
      Function(String) onChanged,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        DropdownButton<String>(
          value: currentValue,
          underline: Container(),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(error, style: TextStyle(color: Colors.red.shade700)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(todoProvider.notifier).fetchTodos(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList(List<Todo> todos) {
    // Apply filters
    final filteredTodos = todos.where((todo) {
      if (_filterStatus != 'All' && todo.status != _filterStatus) return false;
      if (_filterPriority != 'All' && todo.priority != _filterPriority) {
        return false;
      }
      return true;
    }).toList();

    if (filteredTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No tasks found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Create a new task', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(todoProvider.notifier).fetchTodos(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTodos.length,
        itemBuilder: (context, index) {
          return _buildTodoCard(filteredTodos[index]);
        },
      ),
    );
  }

  Widget _buildTodoCard(Todo todo) {
    final dueDate = DateFormat('MMM dd, yyyy').format(todo.dueDate);
    final isOverdue = todo.isOverdue;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _showTodoDetails(todo),
        title: Text(
          todo.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                todo.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildChip(
                  icon: Icons.calendar_today,
                  label: dueDate,
                  color: isOverdue ? Colors.red : Colors.blue,
                ),
                _buildStatusChip(todo.status),
                _buildChip(
                  icon: Icons.flag,
                  label: todo.priority,
                  color: _getPriorityColor(todo.priority),
                ),
                if (todo.assignedToName != null)
                  _buildChip(
                    icon: Icons.person,
                    label: todo.assignedToName!,
                    color: Colors.purple,
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTodoScreen(todo: todo),
                ),
              );
            } else if (value == 'delete') {
              _showDeleteDialog(todo);
            } else if (value == 'approve') {
              _approveTodo(todo);
            } else if (value == 'reject') {
              _rejectTodo(todo);
            }
          },
          itemBuilder: (context) => [
            if (todo.status != 'Approved') ...[
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
            ],
            if (todo.status == 'Completed') ...[
              const PopupMenuItem(
                value: 'approve',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Approve'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reject',
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 20, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Reject'),
                  ],
                ),
              ),
            ],
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Approved':
        color = Colors.blue;
        icon = Icons.verified;
        break;
      default:
        color = Colors.orange;
        icon = Icons.fiber_new;
    }

    return _buildChip(icon: icon, label: status, color: color);
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

  void _showTodoDetails(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => TodoDetailsDialog(todo: todo),
    );
  }

  void _showDeleteDialog(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(todoProvider.notifier)
                  .deleteTodo(todo.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Task deleted successfully'
                          : 'Failed to delete task',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveTodo(Todo todo) async {
    final success = await ref.read(todoProvider.notifier).approveTodo(todo.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Task approved successfully' : 'Failed to approve task',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectTodo(Todo todo) async {
    final success = await ref.read(todoProvider.notifier).rejectTodo(todo.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Task rejected successfully' : 'Failed to reject task',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}