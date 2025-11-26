// lib/src/features/home/dashboard/models/dashboard_models.dart

import 'package:flutter/material.dart';

/// Enum for time period filter
enum TimePeriod { month, year, custom }

/// Enum for comparison filter (Prev, Now, Next)
enum ComparisonPeriod { prev, now, next }

/// Model for stat panel data
class StatData {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final String trend; // e.g., "+12.5%" or "-3.2%"
  final bool isPositive;

  StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend = '',
    this.isPositive = true,
  });
}

/// Model for chart data points
class ChartDataPoint {
  final String label; // Date, month name, etc.
  final double value;
  final DateTime date;

  ChartDataPoint({
    required this.label,
    required this.value,
    required this.date,
  });
}

/// Model for expense category data
class ExpenseCategoryData {
  final String category;
  final double amount;
  final Color color;

  ExpenseCategoryData({
    required this.category,
    required this.amount,
    required this.color,
  });
}

/// Model for comparison chart data (prev, now, next)
class ComparisonChartData {
  final List<ChartDataPoint> prevData;
  final List<ChartDataPoint> nowData;
  final List<ChartDataPoint> nextData;

  ComparisonChartData({
    required this.prevData,
    required this.nowData,
    required this.nextData,
  });
}

/// Model for date range filter
class DateRangeFilter {
  final DateTime startDate;
  final DateTime endDate;

  DateRangeFilter({
    required this.startDate,
    required this.endDate,
  });

  DateRangeFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return DateRangeFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}