import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'providers/todo_provider.dart';
import 'models/todo_model.dart';
import 'todo_details_dialog.dart';
import 'approve_reject_dialog.dart';

class MyTodosView extends ConsumerStatefulWidget {
  const MyTodosView({super.key});

  @override
  ConsumerState<MyTodosView> createState() => _MyTodosViewState();
}

class _MyTodosViewState extends ConsumerState<MyTodosView> {
  String _sortBy = 'Priority'; // 'Priority' or 'DueDate'
  bool _sortAscending = false; // false = desc, true = asc
  String _filterStatus = 'All';
  String _filterPriority = 'All';

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(myTodoProvider);

    return Column(
      children: [
        // Filter and Sort Section
        _buildControlSection(),

        // Todo Grid
        Expanded(
          child: todoState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : todoState.error != null
              ? _buildErrorWidget(todoState.error!)
              : _buildTodoGrid(todoState.todos),
        ),
      ],
    );
  }

  Widget _buildControlSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters & Sort',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _sortAscending = !_sortAscending);
                    },
                    tooltip: _sortAscending ? 'Ascending' : 'Descending',
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
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDropdown('Sort', _sortBy, ['Priority', 'DueDate'], (value) {
                  setState(() => _sortBy = value);
                }),
                const SizedBox(width: 16),
                _buildDropdown('Status', _filterStatus, [
                  'All', 'New', 'Completed', 'Approved'
                ], (value) {
                  setState(() => _filterStatus = value);
                }),
                const SizedBox(width: 16),
                _buildDropdown('Priority', _filterPriority, [
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

  Widget _buildDropdown(
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
            return DropdownMenuItem(value: option, child: Text(option));
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
            onPressed: () => ref.read(myTodoProvider.notifier).fetchMyTodos(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoGrid(List<Todo> todos) {
    // Apply filters
    var filteredTodos = todos.where((todo) {
      if (_filterStatus != 'All' && todo.status != _filterStatus) return false;
      if (_filterPriority != 'All' && todo.priority != _filterPriority) return false;
      return true;
    }).toList();

    // Apply sorting
    filteredTodos.sort((a, b) {
      int comparison;
      if (_sortBy == 'Priority') {
        final priorityOrder = {'High': 3, 'Medium': 2, 'Low': 1};
        comparison = (priorityOrder[a.priority] ?? 0).compareTo(priorityOrder[b.priority] ?? 0);
      } else {
        comparison = a.dueDate.compareTo(b.dueDate);
      }
      return _sortAscending ? comparison : -comparison;
    });

    if (filteredTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No todos assigned', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(myTodoProvider.notifier).fetchMyTodos(),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredTodos.length,
        itemBuilder: (context, index) {
          return _buildTodoTile(filteredTodos[index]);
        },
      ),
    );
  }

  Widget _buildTodoTile(Todo todo) {
    final isOverdue = todo.isOverdue;
    Color borderColor = _getBorderColor(todo.priority, isOverdue, todo.status);

    return GestureDetector(
      onTap: () {
        if (todo.status == 'Completed') {
          _showApproveRejectDialog(todo);
        } else {
          _showTodoDetails(todo);
        }
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              _buildStatusBadge(todo.status),
              const SizedBox(height: 8),

              // Title
              Text(
                todo.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Description
              if (todo.description.isNotEmpty)
                Text(
                  todo.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const Spacer(),

              // Due date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isOverdue ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd').format(todo.dueDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdue ? Colors.red : Colors.grey.shade700,
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _getPriorityColor(todo.priority).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getPriorityColor(todo.priority).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  todo.priority,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPriorityColor(todo.priority),
                  ),
                ),
              ),

              // Done button
              if (todo.status == 'New') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _completeTodo(todo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Done', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getBorderColor(String priority, bool isOverdue, String status) {
    if (isOverdue && status == 'New') return Colors.red;
    if (status == 'Completed') return Colors.green;
    if (status == 'Approved') return Colors.blue;

    switch (priority) {
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow.shade700;
      case 'Low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
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

  void _showApproveRejectDialog(Todo todo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ApproveRejectDialog(
        todo: todo,
        onApprove: () async {
          Navigator.pop(context);
          await ref.read(todoProvider.notifier).approveTodo(todo.id);
          ref.read(myTodoProvider.notifier).fetchMyTodos();
        },
        onReject: () async {
          Navigator.pop(context);
          await ref.read(todoProvider.notifier).rejectTodo(todo.id);
          ref.read(myTodoProvider.notifier).fetchMyTodos();
        },
      ),
    );
  }

  Future<void> _completeTodo(Todo todo) async {
    // Open camera to take photos
    final ImagePicker picker = ImagePicker();
    List<String> imagePaths = [];

    // Show dialog to take multiple photos
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Task'),
        content: const Text(
          'Take photos to complete this task. You can take multiple photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Take photos loop
              bool takingPhotos = true;
              while (takingPhotos) {
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );

                if (photo != null) {
                  imagePaths.add(photo.path);

                  if (mounted) {
                    final takeMore = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Photo Captured'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.file(
                              File(photo.path),
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 16),
                            Text('${imagePaths.length} photo(s) captured'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Done'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Take More'),
                          ),
                        ],
                      ),
                    );

                    if (takeMore != true) {
                      takingPhotos = false;
                    }
                  } else {
                    takingPhotos = false;
                  }
                } else {
                  takingPhotos = false;
                }
              }

              // Upload and complete
              if (imagePaths.isNotEmpty) {
                final success = await ref
                    .read(myTodoProvider.notifier)
                    .completeTodo(todo.id, imagePaths);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Task completed successfully'
                            : 'Failed to complete task',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Take Photo'),
          ),
        ],
      ),
    );
  }
}