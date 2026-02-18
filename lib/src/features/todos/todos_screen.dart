import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/rbac.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_state.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/rbac_gate.dart';
import 'providers/todo_provider.dart';
import 'tasks_view.dart';
import 'my_todos_view.dart';
import 'add_todo_screen.dart';

class TodosScreen extends ConsumerStatefulWidget {
  const TodosScreen({super.key});

  @override
  ConsumerState<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends ConsumerState<TodosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showTasks = true;
  bool _showMyTodos = true;

  @override
  void initState() {
    super.initState();
    
    // Determine visibility based on proper role types from MongoDB
    final authState = ref.read(authProvider);
    final role = authState.maybeWhen(
      authenticated: (_, role, __) => role.toLowerCase(),
      orElse: () => '',
    );
    
    // Define role categories
    final isManagement = Rbac.isAdmin(role) || role == 'owner' || role == 'manager';
    
    // Strict Role-Based Visibility:
    // 1. Admins & Managers see ONLY Oversight (Tab: Tasks)
    // 2. Staff see ONLY their specific work (Tab: My Todos)
    
    if (isManagement) {
      _showTasks = true;
      _showMyTodos = false;
    } else {
      _showTasks = false;
      _showMyTodos = true;
    }
    
    final tabCount = (_showTasks ? 1 : 0) + (_showMyTodos ? 1 : 0);
    _tabController = TabController(length: tabCount, vsync: this);

    // Initial data fetch
    Future.microtask(() {
      if (_showTasks) ref.read(todoProvider.notifier).fetchTodos();
      if (_showMyTodos) ref.read(myTodoProvider.notifier).fetchMyTodos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showTabs = _showTasks && _showMyTodos;

    return RbacGate(
      permission: AppPermission.todos,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFACC15), // Yellow
          foregroundColor: const Color(0xFF333333), // Dark Grey
          title: const Text('Todos'),
          elevation: 0,
          bottom: showTabs
              ? TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF333333), // Dark Grey
                  labelColor: const Color(0xFF333333),
                  unselectedLabelColor: Colors.black54,
                  tabs: [
                    if (_showTasks)
                      const Tab(
                        icon: Icon(Icons.list_alt),
                        text: 'Tasks',
                      ),
                    if (_showMyTodos)
                      const Tab(
                        icon: Icon(Icons.assignment_ind),
                        text: 'My Todos',
                      ),
                  ],
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final activeTab = _showTasks && _showMyTodos
                    ? (_tabController.index == 0 ? 'tasks' : 'mytodos')
                    : (_showTasks ? 'tasks' : 'mytodos');

                if (activeTab == 'tasks') {
                  ref.read(todoProvider.notifier).fetchTodos();
                } else {
                  ref.read(myTodoProvider.notifier).fetchMyTodos();
                }
              },
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: TabBarView(
          controller: _tabController,
          children: [
            if (_showTasks) const TasksView(),
            if (_showMyTodos) const MyTodosView(),
          ],
        ),
        floatingActionButton: (_showTasks && _tabController.index == 0)
            ? FloatingActionButton(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: Colors.white,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTodoScreen(),
                    ),
                  );

                  // Refresh if task was created
                  if (result == true) {
                    ref.read(todoProvider.notifier).fetchTodos();
                  }
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}
