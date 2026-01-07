import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/app_drawer.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch both types of todos on init
    Future.microtask(() {
      ref.read(todoProvider.notifier).fetchTodos();
      ref.read(myTodoProvider.notifier).fetchMyTodos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFACC15), // Yellow
        foregroundColor: const Color(0xFF333333), // Dark Grey
        title: const Text('Todos'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF333333), // Dark Grey
          labelColor: const Color(0xFF333333),
          unselectedLabelColor: Colors.black54,
          tabs: const [
            Tab(
              icon: Icon(Icons.list_alt),
              text: 'Tasks',
            ),
            Tab(
              icon: Icon(Icons.assignment_ind),
              text: 'My Todos',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabController.index == 0) {
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
        children: const [
          TasksView(),
          MyTodosView(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
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
    );
  }
}