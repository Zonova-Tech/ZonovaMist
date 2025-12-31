import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../services/expense_service.dart';
import 'add_expense_page.dart';
import 'edit_expense_page.dart';
import 'view_expense_page.dart';


class ExpensesListPage extends StatefulWidget {
  const ExpensesListPage({super.key});

  @override
  State<ExpensesListPage> createState() => _ExpensesListPageState();
}

class _ExpensesListPageState extends State<ExpensesListPage> {
  // List of expense items fetched from API
  List<Map<String, dynamic>> _items = [];

  // Loading state indicator
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Load expenses when page is initialized
    _load();
  }

  /// Fetch all expenses from the API
  /// Updates the expenses list and handles loading state
  /// Shows error message if fetch fails
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Fetch expenses from service
      final list = await ExpenseService.fetchExpenses();

      // Process and update state with fetched data
      setState(() {
        _items = list.map((e) {
          final m = Map<String, dynamic>.from(e);
          // Ensure each item has an 'id' field
          m['id'] = m['_id'] ?? m['id'];
          return m;
        }).toList();
      });
    } catch (e) {
      // Show error message if load fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Load failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Open add expense page and handle result
  /// Creates new expense via API and updates list
  /// Shows success or error message
  void _openAdd() async {
    // Navigate to add expense page
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpensePage()),
    );

    // If data returned, create expense via API
    if (res != null) {
      try {
        final created = await ExpenseService.createExpense(res);

        // Add new expense to the top of the list
        setState(() {
          _items.insert(0, {...created, 'id': created['_id'] ?? created['id']});
        });

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Expense saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Show error message if save fails
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Save failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Open edit expense page and handle result
  /// Updates expense via API and refreshes list
  /// Shows success or error message
  void _onEdit(Map<String, dynamic> e) async {
    // Navigate to edit expense page
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditExpensePage(expense: e)),
    );

    // If data returned, update expense via API
    if (res != null) {
      try {
        final upd = await ExpenseService.updateExpense(e['id'], res);

        // Update expense in the list
        setState(() {
          final index = _items.indexWhere((el) => el['id'] == e['id']);
          if (index != -1) {
            _items[index] = {...upd, 'id': upd['_id'] ?? upd['id']};
          }
        });

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Expense updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (err) {
        // Show error message if update fails
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Update failed: $err'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Delete expense with confirmation dialog
  /// Removes expense via API and updates list
  /// Shows success or error message
  void _onDelete(Map<String, dynamic> e) async {
    // Show confirmation dialog
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${e['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // If confirmed, delete expense via API
    if (ok == true) {
      try {
        await ExpenseService.deleteExpense(e['id']);

        // Remove expense from list
        setState(() => _items.removeWhere((el) => el['id'] == e['id']));

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Expense deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (err) {
        // Show error message if delete fails
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Delete failed: $err'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          // Refresh button to reload expenses
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),

      body: _loading
      // Show loading indicator while fetching data
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
      // Show empty state with add button if no expenses
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No expenses yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
          ],
        ),
      )
      // Show list of expenses with swipe actions
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final e = _items[index];

            // Slidable widget for swipe actions (edit/delete)
            return Slidable(
              key: ValueKey(e['id']),
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.4,
                children: [
                  // Edit action (swipe left)
                  SlidableAction(
                    onPressed: (_) => _onEdit(e),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Edit',
                  ),
                  // Delete action (swipe left)
                  SlidableAction(
                    onPressed: (_) => _onDelete(e),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                  ),
                ],
              ),

              // Expense card - tap to view details
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  child: ListTile(
                    onTap: () {
                      // Navigate to view expense details page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewExpensePage(expense: e),
                        ),
                      );
                    },
                    // Expense title
                    title: Text(
                      e['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Expense category and date
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${e['category']}'),
                        Text(
                          e['date']?.toString().split('T')[0] ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    // Chevron icon indicating tap to view
                    trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // Floating action button to add new expense
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}