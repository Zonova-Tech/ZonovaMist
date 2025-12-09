import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_drawer.dart';
import 'providers/dashboard_provider.dart';
import 'models/dashboard_models.dart';
import 'widgets/stat_panel.dart';
import 'widgets/filter_chips_row.dart';
import 'widgets/revenue_comparison_chart.dart';
import 'widgets/expense_comparison_chart.dart';
import 'widgets/expense_category_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Custom Date Range',
            onPressed: () => _showDateRangePicker(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              // Trigger refresh
              ref.invalidate(dashboardProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            const SizedBox(height: 24),

            // Filter Chips
            FilterChipsRow(
              timePeriod: dashboardState.timePeriod,
              selectedComparisons: dashboardState.selectedComparisons,
              onTimePeriodChanged: notifier.setTimePeriod,
              onComparisonToggled: notifier.toggleComparison,
            ),
            const SizedBox(height: 24),

            // Stat Panel
            StatPanel(stats: notifier.getStatPanelData()),
            const SizedBox(height: 24),

            // Revenue Comparison Chart
            _buildSectionTitle('Revenue Comparison'),
            const SizedBox(height: 12),
            RevenueComparisonChart(
              data: notifier.getRevenueComparisonData(),
              selectedComparisons: dashboardState.selectedComparisons,
              timePeriod: dashboardState.timePeriod,
            ),
            const SizedBox(height: 24),

            // Expense Comparison Chart
            _buildSectionTitle('Expense Comparison'),
            const SizedBox(height: 12),
            ExpenseComparisonChart(
              data: notifier.getExpenseComparisonData(),
              selectedComparisons: dashboardState.selectedComparisons,
              timePeriod: dashboardState.timePeriod,
            ),
            const SizedBox(height: 24),

            // Expense Category Chart
            _buildSectionTitle('Expenses by Category'),
            const SizedBox(height: 12),
            ExpenseCategoryChart(
              data: notifier.getExpenseCategoryData(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.hotel,
                          size: 32,
                          color: Colors.blue.shade700,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zonova Mist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Guest House Management',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome back!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(dashboardProvider.notifier);
    final now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      notifier.setCustomDateRange(
        DateRangeFilter(
          startDate: picked.start,
          endDate: picked.end,
        ),
      );
    }
  }
}