// lib/src/features/home/dashboard/providers/dashboard_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/dashboard_models.dart';

/// Provider for dashboard state
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});

/// Dashboard state
class DashboardState {
  final TimePeriod timePeriod;
  final Set<ComparisonPeriod> selectedComparisons;
  final DateRangeFilter? customDateRange;
  final bool isLoading;

  DashboardState({
    this.timePeriod = TimePeriod.month,
    Set<ComparisonPeriod>? selectedComparisons,
    this.customDateRange,
    this.isLoading = false,
  }) : selectedComparisons = selectedComparisons ?? {ComparisonPeriod.now};

  DashboardState copyWith({
    TimePeriod? timePeriod,
    Set<ComparisonPeriod>? selectedComparisons,
    DateRangeFilter? customDateRange,
    bool? isLoading,
  }) {
    return DashboardState(
      timePeriod: timePeriod ?? this.timePeriod,
      selectedComparisons: selectedComparisons ?? this.selectedComparisons,
      customDateRange: customDateRange ?? this.customDateRange,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Dashboard notifier with dummy data generation
class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(DashboardState());

  void setTimePeriod(TimePeriod period) {
    state = state.copyWith(timePeriod: period);
  }

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
  }

  void setCustomDateRange(DateRangeFilter dateRange) {
    state = state.copyWith(
      timePeriod: TimePeriod.custom,
      customDateRange: dateRange,
    );
  }

  /// Generate stat panel data (dummy)
  List<StatData> getStatPanelData() {
    return [
      StatData(
        title: 'Revenue',
        value: 125340.50,
        icon: Icons.trending_up,
        color: Colors.green,
        trend: '+12.5%',
        isPositive: true,
      ),
      StatData(
        title: 'Advances',
        value: 45200.00,
        icon: Icons.payments,
        color: Colors.blue,
        trend: '+8.3%',
        isPositive: true,
      ),
      StatData(
        title: 'Commission',
        value: 8750.25,
        icon: Icons.account_balance_wallet,
        color: Colors.orange,
        trend: '+5.2%',
        isPositive: true,
      ),
      StatData(
        title: 'Expenses',
        value: 32450.75,
        icon: Icons.money_off,
        color: Colors.red,
        trend: '-3.1%',
        isPositive: true,
      ),
    ];
  }

  /// Generate revenue comparison data (dummy)
  ComparisonChartData getRevenueComparisonData() {
    final now = DateTime.now();
    return _generateComparisonData(now, baseAmount: 4000, variance: 1500);
  }

  /// Generate expense comparison data (dummy)
  ComparisonChartData getExpenseComparisonData() {
    final now = DateTime.now();
    return _generateComparisonData(now, baseAmount: 1200, variance: 500);
  }

  /// Generate expense category data (dummy)
  List<ExpenseCategoryData> getExpenseCategoryData() {
    return [
      ExpenseCategoryData(
        category: 'Light Bill',
        amount: 5200.00,
        color: Colors.amber,
      ),
      ExpenseCategoryData(
        category: 'Water Bill',
        amount: 2800.00,
        color: Colors.blue,
      ),
      ExpenseCategoryData(
        category: 'Internet Bill',
        amount: 3500.00,
        color: Colors.purple,
      ),
      ExpenseCategoryData(
        category: 'Salary',
        amount: 15000.00,
        color: Colors.green,
      ),
      ExpenseCategoryData(
        category: 'Cleaning',
        amount: 1800.00,
        color: Colors.teal,
      ),
      ExpenseCategoryData(
        category: 'Rent',
        amount: 8000.00,
        color: Colors.orange,
      ),
      ExpenseCategoryData(
        category: 'Purchases',
        amount: 4150.75,
        color: Colors.pink,
      ),
    ];
  }

  /// Private helper to generate comparison data
  ComparisonChartData _generateComparisonData(
      DateTime now, {
        required double baseAmount,
        required double variance,
      }) {
    final random = Random();

    switch (state.timePeriod) {
      case TimePeriod.week:
        return _generateWeeklyData(now, baseAmount, variance, random);
      case TimePeriod.month:
        return _generateMonthlyData(now, baseAmount, variance, random);
      case TimePeriod.year:
        return _generateYearlyData(now, baseAmount, variance, random);
      case TimePeriod.custom:
        if (state.customDateRange != null) {
          return _generateCustomData(
            state.customDateRange!,
            baseAmount,
            variance,
            random,
          );
        }
        return _generateMonthlyData(now, baseAmount, variance, random);
    }
  }

  ComparisonChartData _generateWeeklyData(
      DateTime now,
      double baseAmount,
      double variance,
      Random random,
      ) {
    return ComparisonChartData(
      prevData: _generateDataPoints(7, now.subtract(const Duration(days: 14)), baseAmount * 0.9, variance, random),
      nowData: _generateDataPoints(7, now.subtract(const Duration(days: 7)), baseAmount, variance, random),
      nextData: _generateDataPoints(7, now, baseAmount * 1.1, variance, random),
    );
  }

  ComparisonChartData _generateMonthlyData(
      DateTime now,
      double baseAmount,
      double variance,
      Random random,
      ) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    final currentMonth = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    return ComparisonChartData(
      prevData: _generateDataPoints(daysInMonth, prevMonth, baseAmount * 0.85, variance, random),
      nowData: _generateDataPoints(daysInMonth, currentMonth, baseAmount, variance, random),
      nextData: _generateDataPoints(daysInMonth, nextMonth, baseAmount * 1.15, variance, random),
    );
  }

  ComparisonChartData _generateYearlyData(
      DateTime now,
      double baseAmount,
      double variance,
      Random random,
      ) {
    final prevYear = DateTime(now.year - 1, 1, 1);
    final currentYear = DateTime(now.year, 1, 1);
    final nextYear = DateTime(now.year + 1, 1, 1);

    return ComparisonChartData(
      prevData: _generateMonthlyDataPoints(12, prevYear, baseAmount * 0.8, variance, random),
      nowData: _generateMonthlyDataPoints(12, currentYear, baseAmount, variance, random),
      nextData: _generateMonthlyDataPoints(12, nextYear, baseAmount * 1.2, variance, random),
    );
  }

  ComparisonChartData _generateCustomData(
      DateRangeFilter dateRange,
      double baseAmount,
      double variance,
      Random random,
      ) {
    final daysDiff = dateRange.endDate.difference(dateRange.startDate).inDays;
    final duration = Duration(days: daysDiff);

    return ComparisonChartData(
      prevData: _generateDataPoints(
        daysDiff,
        dateRange.startDate.subtract(duration),
        baseAmount * 0.9,
        variance,
        random,
      ),
      nowData: _generateDataPoints(
        daysDiff,
        dateRange.startDate,
        baseAmount,
        variance,
        random,
      ),
      nextData: _generateDataPoints(
        daysDiff,
        dateRange.endDate,
        baseAmount * 1.1,
        variance,
        random,
      ),
    );
  }

  List<ChartDataPoint> _generateDataPoints(
      int count,
      DateTime startDate,
      double baseAmount,
      double variance,
      Random random,
      ) {
    return List.generate(count, (index) {
      final date = startDate.add(Duration(days: index));
      final value = baseAmount + (random.nextDouble() - 0.5) * variance;
      return ChartDataPoint(
        label: '${date.day}',
        value: value.clamp(0, double.infinity),
        date: date,
      );
    });
  }

  List<ChartDataPoint> _generateMonthlyDataPoints(
      int count,
      DateTime startDate,
      double baseAmount,
      double variance,
      Random random,
      ) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return List.generate(count, (index) {
      final date = DateTime(startDate.year, startDate.month + index, 1);
      final value = baseAmount + (random.nextDouble() - 0.5) * variance;
      return ChartDataPoint(
        label: monthNames[date.month - 1],
        value: value.clamp(0, double.infinity),
        date: date,
      );
    });
  }
}