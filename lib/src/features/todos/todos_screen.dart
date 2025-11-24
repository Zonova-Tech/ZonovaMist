import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/app_drawer.dart';
import 'providers/todo_provider.dart';
import 'models/todo_model.dart';
import 'add_todo_screen.dart';

class TodosScreen extends ConsumerStatefulWidget {
  const TodosScreen({super.key});

  @override
  ConsumerState<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends ConsumerState<TodosScreen> {
  String _filterPriority = 'All';
  bool _showCompleted = true;

  @override
  void initState() {
    super.initState();
    // Fetch todos on init
    Future.microtask(() => ref.read(todoProvider.notifier).fetchTodos());
  }

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(todoProvider.notifier).fetchTodos();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: todoState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : todoState.error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              todoState.error!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(todoProvider.notifier).fetchTodos();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      )
          : _buildTodoList(todoState.todos),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTodoScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodoList(List<Todo> todos) {
    // Apply filters
    final filteredTodos = todos.where((todo) {
      if (!_showCompleted && todo.completed) return false;
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
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No todos found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create a new todo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
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
    final isOverdue = !todo.completed &&
        todo.dueDate.isBefore(DateTime.now());

    Color priorityColor;
    IconData priorityIcon;

    switch (todo.priority) {
      case 'High':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'Low':
        priorityColor = Colors.green;
        priorityIcon = Icons.low_priority;
        break;
      default:
        priorityColor = Colors.orange;
        priorityIcon = Icons.drag_handle;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: todo.completed
              ? Colors.grey.shade300
              : (isOverdue ? Colors.red.shade200 : Colors.transparent),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Checkbox(
          value: todo.completed,
          onChanged: (value) {
            ref.read(todoProvider.notifier).toggleTodoComplete(todo.id);
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: todo.completed
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: todo.completed ? Colors.grey : Colors.black87,
          ),
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
                style: TextStyle(
                  color: todo.completed
                      ? Colors.grey.shade500
                      : Colors.grey.shade700,
                  fontSize: 14,
                ),
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
                _buildChip(
                  icon: priorityIcon,
                  label: todo.priority,
                  color: priorityColor,
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
            }
          },
          itemBuilder: (context) => [
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
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Todos'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Priority',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['All', 'High', 'Medium', 'Low'].map((priority) {
                    return ChoiceChip(
                      label: Text(priority),
                      selected: _filterPriority == priority,
                      onSelected: (selected) {
                        setState(() {
                          _filterPriority = priority;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Show completed'),
                  value: _showCompleted,
                  onChanged: (value) {
                    setState(() {
                      _showCompleted = value ?? true;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Trigger rebuild with new filters
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
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
                          ? 'Todo deleted successfully'
                          : 'Failed to delete todo',
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
}