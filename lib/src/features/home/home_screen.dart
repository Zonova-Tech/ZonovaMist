import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the charting library
import 'package:map_market/src/core/auth/auth_provider.dart';
import 'package:map_market/src/core/auth/auth_state.dart';

import '../../core/i18n/arb/app_localizations.dart';

// Main HomeScreen Widget
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Use a switch statement to handle the different authentication states
    return switch (authState) {
      AuthLoading() => const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthError(:final message) => Scaffold(body: Center(child: Text('Error: $message'))),
      Unauthenticated() => const Scaffold(body: Center(child: Text('Not logged in.'))),
      Authenticated(:final userName) => DashboardScaffold(userName: userName),
      // TODO: Handle this case.
      AuthState() => throw UnimplementedError(),
    };
  }
}

// The main scaffold for the dashboard, containing the AppBar and Drawer
class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.welcome),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      drawer: const _AppDrawer(),
      body: _DashboardContent(userName: userName),
      backgroundColor: Colors.grey[200], // A neutral background color
    );
  }
}

// The Navigation Drawer (Sidebar)
class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'MapMarket Menu',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Products'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Orders'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context); // Close the drawer
            },
          ),
        ],
      ),
    );
  }
}

// The main scrollable content of the dashboard
class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome Header
          Text('Welcome back,', style: Theme.of(context).textTheme.titleLarge),
          Text(
            userName,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // 2. Dummy Stats Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _StatCard(
                icon: Icons.point_of_sale,
                title: 'Total Sales',
                value: '\$14,594',
                color: Colors.blue,
              ),
              _StatCard(
                icon: Icons.receipt,
                title: 'Total Orders',
                value: '1,287',
                color: Colors.orange,
              ),
              _StatCard(
                icon: Icons.people,
                title: 'New Customers',
                value: '39',
                color: Colors.green,
              ),
              _StatCard(
                icon: Icons.inventory,
                title: 'Products',
                value: '452',
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Weekly Sales Chart
          _SectionTitle(title: 'Weekly Sales'),
          const SizedBox(height: 8),
          const _WeeklySalesChart(),
          const SizedBox(height: 24),

          // 4. Recent Orders Table
          _SectionTitle(title: 'Recent Orders'),
          const SizedBox(height: 8),
          const _RecentOrdersTable(),
        ],
      ),
    );
  }
}

// A reusable widget for section titles
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

// A reusable card for displaying a single statistic
class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.title, required this.value, required this.color});
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

// A widget for the dummy sales bar chart
class _WeeklySalesChart extends StatelessWidget {
  const _WeeklySalesChart();

  @override
  Widget build(BuildContext context) {
    // FIX: Pass the context to the _makeGroupData function
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: SizedBox(
          height: 150,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 20,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                _makeGroupData(0, 5, context),
                _makeGroupData(1, 6.5, context),
                _makeGroupData(2, 5, context),
                _makeGroupData(3, 7.5, context),
                _makeGroupData(4, 9, context),
                _makeGroupData(5, 11.5, context),
                _makeGroupData(6, 6.5, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14);
    String text;
    switch (value.toInt()) {
      case 0: text = 'M'; break;
      case 1: text = 'T'; break;
      case 2: text = 'W'; break;
      case 3: text = 'T'; break;
      case 4: text = 'F'; break;
      case 5: text = 'S'; break;
      case 6: text = 'S'; break;
      default: text = ''; break;
    }
    return SideTitleWidget(meta: meta, child: Text(text, style: style));
  }

  // FIX: Accept BuildContext as a parameter to safely get the theme.
  BarChartGroupData _makeGroupData(int x, double y, BuildContext context) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
          toY: y,
          color: Theme.of(context).colorScheme.secondary, // FIX: Use the passed context.
          width: 22,
          borderRadius: BorderRadius.circular(6)
      )
    ]);
  }
}

// FIX: The unnecessary Keys class has been removed.

// A widget for the dummy recent orders data table
class _RecentOrdersTable extends StatelessWidget {
  const _RecentOrdersTable();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Order ID')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Status')),
          ],
          rows: [
            _createDataRow('#1287', '\$250.00', 'Completed'),
            _createDataRow('#1286', '\$135.50', 'Completed'),
            _createDataRow('#1285', '\$78.20', 'Shipped'),
            _createDataRow('#1284', '\$450.00', 'Pending'),
          ],
        ),
      ),
    );
  }

  DataRow _createDataRow(String orderId, String amount, String status) {
    return DataRow(cells: [
      DataCell(Text(orderId)),
      DataCell(Text(amount)),
      DataCell(
        Text(status, style: TextStyle(
            color: status == 'Completed' ? Colors.green : (status == 'Shipped' ? Colors.orange : Colors.red),
            fontWeight: FontWeight.bold)
        ),
      ),
    ]);
  }
}