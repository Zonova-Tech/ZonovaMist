import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'providers/todo_provider.dart';
import 'models/todo_model.dart';
import 'add_todo_screen.dart';
import 'todo_details_dialog.dart';
import 'approve_reject_dialog.dart';

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
        _buildFilterSection(),
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
              const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: () => setState(() {
                  _filterStatus = 'All';
                  _filterPriority = 'All';
                }),
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
                _buildFilterChip('Status', _filterStatus, ['All', 'New', 'Completed', 'Approved'], (value) {
                  setState(() => _filterStatus = value);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Priority', _filterPriority, ['All', 'High', 'Medium', 'Low'], (value) {
                  setState(() => _filterPriority = value);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String currentValue, List<String> options, Function(String) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        DropdownButton<String>(
          value: currentValue,
          underline: Container(),
          items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
          onChanged: (value) { if (value != null) onChanged(value); },
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
    final filteredTodos = todos.where((todo) {
      if (_filterStatus != 'All' && todo.status != _filterStatus) return false;
      if (_filterPriority != 'All' && todo.priority != _filterPriority) return false;
      return true;
    }).toList();

    if (filteredTodos.isEmpty) {
      return const Center(child: Text('No tasks found', style: TextStyle(fontSize: 18, color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(todoProvider.notifier).fetchTodos(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTodos.length,
        itemBuilder: (context, index) => _buildTodoCard(filteredTodos[index]),
      ),
    );
  }

  Widget _buildTodoCard(Todo todo) {
    final hasRating = todo.rating != null;
    final hasComment = todo.ratingComment != null && todo.ratingComment!.isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias, // Ensures image doesn't overlap rounded corners
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TASK IMAGE (CLICK TO APPROVE/REJECT IF COMPLETED) ---
          if (todo.images.isNotEmpty)
            InkWell(
              onTap: () {
                if (todo.status == 'Completed') {
                  _showApproveRejectDialog(todo);
                } else {
                  _showTodoDetails(todo);
                }
              },
              child: Image.network(
                todo.images.first.url,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                ),
              ),
            ),
          
          InkWell(
            onTap: () => _showTodoDetails(todo),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          todo.title, 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                      ),
                      if (todo.status == 'Approved' && hasRating)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                todo.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => AddTodoScreen(todo: todo)));
                          if (val == 'delete') _deleteTodo(todo.id);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                  if (todo.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(todo.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                  if (todo.status == 'Approved' && hasComment) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Review: ${todo.ratingComment!}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (todo.status == 'New' && todo.rejectionComment != null && todo.rejectionComment!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Feedback: ${todo.rejectionComment!}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(todo.status),
                      _buildChip(Icons.flag, todo.priority, _getPriorityColor(todo.priority)),
                      if (todo.assignedToName != null) 
                        _buildChip(Icons.person, todo.assignedToName!, Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task approved!'), backgroundColor: Colors.green));
          }
        },
        onReject: (comment) async {
          Navigator.pop(context);
          final success = await ref.read(todoProvider.notifier).rejectTodo(todo.id, comment);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Changes requested / Task rejected'), 
              backgroundColor: Colors.orange,
            ));
          }
        },
      ),
    );
  }

  void _showTodoDetails(Todo todo) => showDialog(context: context, builder: (_) => TodoDetailsDialog(todo: todo));

  Future<void> _deleteTodo(String id) async {
    final success = await ref.read(todoProvider.notifier).deleteTodo(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted')));
    }
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))]),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'Completed' ? Colors.green : (status == 'Approved' ? Colors.blue : Colors.orange);
    return _buildChip(status == 'Completed' ? Icons.check_circle : Icons.fiber_new, status, color);
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High': return Colors.red;
      case 'Low': return Colors.green;
      default: return Colors.orange;
    }
  }
}
