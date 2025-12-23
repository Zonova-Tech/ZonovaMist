import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_models.dart';
import '../../../../core/api/dashboard_service.dart';

/// Provider for dashboard service
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

/// Provider for dashboard state
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final service = ref.watch(dashboardServiceProvider);
  return DashboardNotifier(service);
});

/// Dashboard state
class DashboardState {
  final TimePeriod timePeriod;
  final Set<ComparisonPeriod> selectedComparisons;
  final DateRangeFilter? customDateRange;
  final bool isLoading;
  final String? error;

  // Cached data
  final Map<String, StatData>? stats;
  final ComparisonChartData? revenueData;
  final ComparisonChartData? expenseData;
  final List<ExpenseCategoryData>? categoryData;

  DashboardState({
    this.timePeriod = TimePeriod.month,
    Set<ComparisonPeriod>? selectedComparisons,
    this.customDateRange,
    this.isLoading = false,
    this.error,
    this.stats,
    this.revenueData,
    this.expenseData,
    this.categoryData,
  }) : selectedComparisons = selectedComparisons ?? {ComparisonPeriod.now};

  DashboardState copyWith({
    TimePeriod? timePeriod,
    Set<ComparisonPeriod>? selectedComparisons,
    DateRangeFilter? customDateRange,
    bool? isLoading,
    String? error,
    Map<String, StatData>? stats,
    ComparisonChartData? revenueData,
    ComparisonChartData? expenseData,
    List<ExpenseCategoryData>? categoryData,
  }) {
    return DashboardState(
      timePeriod: timePeriod ?? this.timePeriod,
      selectedComparisons: selectedComparisons ?? this.selectedComparisons,
      customDateRange: customDateRange ?? this.customDateRange,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
      revenueData: revenueData ?? this.revenueData,
      expenseData: expenseData ?? this.expenseData,
      categoryData: categoryData ?? this.categoryData,
    );
  }
}

/// Dashboard notifier with real API integration
class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardService _service;

  DashboardNotifier(this._service) : super(DashboardState()) {
    // Load initial data
    loadAllData();
  }

  /// Load all dashboard data
  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.wait([
        loadStats(),
        loadRevenueData(),
        loadExpenseData(),
        loadCategoryData(),
      ]);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard data: $e',
      );
    }
  }

  /// Load statistics
  Future<void> loadStats() async {
    try {
      final stats = await _service.fetchStats(
        timePeriod: state.timePeriod,
        customStartDate: state.customDateRange?.startDate,
        customEndDate: state.customDateRange?.endDate,
      );

      state = state.copyWith(stats: stats);
    } catch (e) {
      print('❌ Error loading stats: $e');
      // Use dummy data as fallback
      state = state.copyWith(stats: _getDummyStats());
    }
  }

  /// Load revenue comparison data
  Future<void> loadRevenueData() async {
    try {
      final revenueData = await _service.fetchRevenueComparison(
        timePeriod: state.timePeriod,
        comparisons: state.selectedComparisons,
        customStartDate: state.customDateRange?.startDate,
        customEndDate: state.customDateRange?.endDate,
      );

      state = state.copyWith(revenueData: revenueData);
    } catch (e) {
      print('❌ Error loading revenue data: $e');
      // Set empty data if API fails
      state = state.copyWith(
        revenueData: ComparisonChartData(
          prevData: [],
          nowData: [],
          nextData: [],
        ),
      );
    }
  }

  /// Load expense comparison data
  Future<void> loadExpenseData() async {
    try {
      final expenseData = await _service.fetchExpenseComparison(
        timePeriod: state.timePeriod,
        comparisons: state.selectedComparisons,
        customStartDate: state.customDateRange?.startDate,
        customEndDate: state.customDateRange?.endDate,
      );

      state = state.copyWith(expenseData: expenseData);
    } catch (e) {
      print('❌ Error loading expense data: $e');
      // Set empty data if API fails
      state = state.copyWith(
        expenseData: ComparisonChartData(
          prevData: [],
          nowData: [],
          nextData: [],
        ),
      );
    }
  }

  /// Load expense category data
  Future<void> loadCategoryData() async {
    try {
      final categoryData = await _service.fetchExpenseCategories(
        timePeriod: state.timePeriod,
        customStartDate: state.customDateRange?.startDate,
        customEndDate: state.customDateRange?.endDate,
      );

      state = state.copyWith(categoryData: categoryData);
    } catch (e) {
      print('❌ Error loading category data: $e');
      // Set empty data if API fails
      state = state.copyWith(categoryData: []);
    }
  }

  /// Set time period and reload data
  void setTimePeriod(TimePeriod period) {
    state = state.copyWith(timePeriod: period);
    loadAllData();
  }

  /// Toggle comparison period and reload data
  void toggleComparison(ComparisonPeriod period) {
    final newComparisons = Set<ComparisonPeriod>.from(state.selectedComparisons);
    if (newComparisons.contains(period)) {
      if (newComparisons.length > 1) {
        newComparisons.remove(period);
      }
    } else {
      newComparisons.add(period);
    }
    state = state.copyWith(selectedComparisons: newComparisons);
    loadAllData();
  }

  /// Set custom date range and reload data
  void setCustomDateRange(DateRangeFilter dateRange) {
    state = state.copyWith(
      timePeriod: TimePeriod.custom,
      customDateRange: dateRange,
    );
    loadAllData();
  }

  /// Get stat panel data (from cached state)
  List<StatData> getStatPanelData() {
    if (state.stats == null) return _getDummyStatsList();

    return [
      state.stats!['revenue']!,
      state.stats!['advances']!,
      state.stats!['commission']!,
      state.stats!['expenses']!,
    ];
  }

  /// Get revenue comparison data (from cached state)
  ComparisonChartData getRevenueComparisonData() {
    return state.revenueData ?? ComparisonChartData(
      prevData: [],
      nowData: [],
      nextData: [],
    );
  }

  /// Get expense comparison data (from cached state)
  ComparisonChartData getExpenseComparisonData() {
    return state.expenseData ?? ComparisonChartData(
      prevData: [],
      nowData: [],
      nextData: [],
    );
  }

  /// Get profit comparison data for the chart (from cached state).
  ///
  /// This computes the profit by subtracting expenses from revenues for the 'now' period.
  /// It expects that the labels on `ChartDataPoint` can be parsed as integers.
  Map<int, double> getProfitComparisonData() {
    final revenueData = state.revenueData?.nowData ?? [];
    final expenseData = state.expenseData?.nowData ?? [];

    if (revenueData.isEmpty) {
      return {};
    }

    final Map<int, double> expenseMap = {};
    for (final point in expenseData) {
      final key = int.tryParse(point.label);
      if (key != null) {
        expenseMap[key] = point.value;
      }
    }

    final Map<int, double> profitData = {};
    for (final point in revenueData) {
      final key = int.tryParse(point.label);
      if (key != null) {
        final expense = expenseMap[key] ?? 0.0;
        profitData[key] = point.value - expense;
      }
    }

    return profitData;
  }

  /// Get expense category data (from cached state)
  List<ExpenseCategoryData> getExpenseCategoryData() {
    return state.categoryData ?? [];
  }

  // Dummy data fallbacks

  Map<String, StatData> _getDummyStats() {
    return {
      'revenue': StatData(
        title: 'Revenue',
        value: 0,
        icon: Icons.trending_up,
        color: Colors.green,
        trend: '+0.0%',
        isPositive: true,
      ),
      'advances': StatData(
        title: 'Advances',
        value: 0,
        icon: Icons.payments,
        color: Colors.blue,
        trend: '+0.0%',
        isPositive: true,
      ),
      'commission': StatData(
        title: 'Commission',
        value: 0,
        icon: Icons.account_balance_wallet,
        color: Colors.orange,
        trend: '+0.0%',
        isPositive: true,
      ),
      'expenses': StatData(
        title: 'Expenses',
        value: 0,
        icon: Icons.money_off,
        color: Colors.red,
        trend: '+0.0%',
        isPositive: true,
      ),
    };
  }

  List<StatData> _getDummyStatsList() {
    final stats = _getDummyStats();
    return [
      stats['revenue']!,
      stats['advances']!,
      stats['commission']!,
      stats['expenses']!,
    ];
  }
}
