import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
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
  bool _isUploading = false; // Track global upload state

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(myTodoProvider);

    return Stack(
      children: [
        Column(
          children: [
            _buildControlSection(),
            if (_isUploading) const LinearProgressIndicator(backgroundColor: Colors.transparent),
            Expanded(
              child: todoState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : todoState.error != null
                  ? _buildErrorWidget(todoState.error!)
                  : _buildTodoGrid(todoState.todos),
            ),
          ],
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
      return RefreshIndicator(
        onRefresh: () => ref.read(myTodoProvider.notifier).fetchMyTodos(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No tasks assigned to you', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  const Text('Only tasks assigned to your user ID appear here.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(myTodoProvider.notifier).fetchMyTodos(),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
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
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TASK IMAGE (IF COMPLETED) ---
            if (todo.images.isNotEmpty)
              GestureDetector(
                onTap: todo.status == 'Completed' ? () {} : null,
                behavior: HitTestBehavior.opaque,
                child: Image.network(
                  todo.images.first.url,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: todo.status == 'Completed' ? () {} : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.grey.shade50,
                  child: Icon(Icons.assignment, color: Colors.grey.shade300, size: 40),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBadge(todo.status),
                  const SizedBox(height: 8),
                  Text(
                    todo.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: isOverdue ? Colors.red : Colors.grey),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(todo.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      todo.priority,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPriorityColor(todo.priority)),
                    ),
                  ),
                  if (todo.status == 'Approved' && todo.rating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          todo.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (todo.status == 'Approved' &&
                      todo.ratingComment != null &&
                      todo.ratingComment!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Review: ${todo.ratingComment!}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (todo.status == 'New') ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : () => _completeTodo(todo),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: const Size(0, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Done', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'Completed' ? Colors.green : (status == 'Approved' ? Colors.blue : Colors.orange);
    IconData icon = status == 'Completed' ? Icons.check_circle : (status == 'Approved' ? Icons.verified : Icons.fiber_new);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Color _getBorderColor(String priority, bool isOverdue, String status) {
    if (isOverdue && status == 'New') return Colors.red;
    if (status == 'Completed') return Colors.green;
    if (status == 'Approved') return Colors.blue;
    return _getPriorityColor(priority).withOpacity(0.5);
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High': return Colors.red;
      case 'Low': return Colors.green;
      default: return Colors.orange;
    }
  }

  void _showTodoDetails(Todo todo) {
    showDialog(context: context, builder: (context) => TodoDetailsDialog(todo: todo));
  }

  void _showApproveRejectDialog(Todo todo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ApproveRejectDialog(
        todo: todo,
        onApprove: (rating, comment) async {
          Navigator.pop(context);
          final success = await ref.read(todoProvider.notifier).approveTodo(todo.id, rating, comment);
          if (success) ref.read(myTodoProvider.notifier).fetchMyTodos();
        },
        onReject: () async {
          Navigator.pop(context);
          final success = await ref.read(todoProvider.notifier).rejectTodo(todo.id);
          if (success) ref.read(myTodoProvider.notifier).fetchMyTodos();
        },
      ),
    );
  }

  Future<void> _completeTodo(Todo todo) async {
    final ImagePicker picker = ImagePicker();
    List<XFile> imageFiles = [];

    // Prompt user to pick MULTIPLE images (efficient)
    try {
      final List<XFile>? picked = await picker.pickMultiImage(imageQuality: 80);
      
      if (picked == null || picked.isEmpty) {
        // Fallback to single picker if multi-picker is canceled or empty
        final XFile? single = await picker.pickImage(
          source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
          imageQuality: 80,
        );
        if (single != null) picked?.add(single);
      }

      if (picked != null && picked.isNotEmpty) {
        imageFiles.addAll(picked);
      } else {
        return; // User canceled
      }
    } catch (e) {
      print('Picker error: $e');
    }

    if (imageFiles.isEmpty) return;

    setState(() => _isUploading = true);

    // Show persistent loading indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing & Uploading photos...', textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    try {
      final success = await ref.read(myTodoProvider.notifier).completeTodoWithXFiles(todo.id, imageFiles);
      
      if (mounted) {
        Navigator.pop(context); // Close dialog
        setState(() => _isUploading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Task completed successfully!' : 'Upload failed. Check console.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          ref.read(myTodoProvider.notifier).fetchMyTodos();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<Widget> _buildImagePreview(XFile photo) async {
    if (kIsWeb) {
      return Image.network(photo.path, fit: BoxFit.contain);
    } else {
      return Image.file(File(photo.path), fit: BoxFit.contain);
    }
  }
}
