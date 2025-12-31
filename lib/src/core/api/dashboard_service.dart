import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../features/home/dashboard/models/dashboard_models.dart';
import './api_service.dart';

// 1. Create a provider for the service
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  // This automatically uses the Dio instance with the BaseURL and Interceptors
  final dio = ref.watch(dioProvider);
  return DashboardService(dio);
});

class DashboardService {
  final Dio _dio;

  // 2. Accept Dio in the constructor
  DashboardService(this._dio);

  /// Fetch dashboard statistics
  Future<Map<String, StatData>> fetchStats({
    required TimePeriod timePeriod,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'timePeriod': _timePeriodToString(timePeriod),
      };

      if (timePeriod == TimePeriod.custom && customStartDate != null && customEndDate != null) {
        queryParams['startDate'] = customStartDate.toIso8601String();
        queryParams['endDate'] = customEndDate.toIso8601String();
      }

      // 3. Use _dio.get
      // Note: No need for baseUrl or json.decode, Dio handles both.
      final response = await _dio.get(
        '/dashboard/stats', // Only the endpoint path
        queryParameters: queryParams,
      );

      // Dio automatically decodes JSON into response.data
      final data = response.data as Map<String, dynamic>;

      return {
        'revenue': StatData(
          title: 'Revenue',
          value: _parseValue(data['revenue']['value']),
          icon: Icons.trending_up,
          color: Colors.green,
          trend: data['revenue']['trend'] as String,
          isPositive: data['revenue']['isPositive'] as bool,
        ),
        'advances': StatData(
          title: 'Advances',
          value: _parseValue(data['advances']['value']),
          icon: Icons.payments,
          color: Colors.blue,
          trend: data['advances']['trend'] as String,
          isPositive: data['advances']['isPositive'] as bool,
        ),
        'commission': StatData(
          title: 'Commission',
          value: _parseValue(data['commission']['value']),
          icon: Icons.account_balance_wallet,
          color: Colors.orange,
          trend: data['commission']['trend'] as String,
          isPositive: data['commission']['isPositive'] as bool,
        ),
        'expenses': StatData(
          title: 'Expenses',
          value: _parseValue(data['expenses']['value']),
          icon: Icons.money_off,
          color: Colors.red,
          trend: data['expenses']['trend'] as String,
          isPositive: data['expenses']['isPositive'] as bool,
        ),
      };
    } on DioException catch (e) {
      // Dio throws DioException on error status codes
      throw Exception('Failed to load stats: ${e.message}');
    } catch (e) {
      print('❌ Error fetching stats: $e');
      rethrow;
    }
  }

  /// Fetch revenue comparison data
  Future<ComparisonChartData> fetchRevenueComparison({
    required TimePeriod timePeriod,
    required Set<ComparisonPeriod> comparisons,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'timePeriod': _timePeriodToString(timePeriod),
        'comparisons': comparisons.map(_comparisonToString).join(','),
      };

      if (timePeriod == TimePeriod.custom && customStartDate != null && customEndDate != null) {
        queryParams['startDate'] = customStartDate.toIso8601String();
        queryParams['endDate'] = customEndDate.toIso8601String();
      }

      final response = await _dio.get(
        '/dashboard/revenue-comparison',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      return ComparisonChartData(
        prevData: _parseChartData(data['prevData'] as List<dynamic>),
        nowData: _parseChartData(data['nowData'] as List<dynamic>),
        nextData: _parseChartData(data['nextData'] as List<dynamic>),
      );
    } catch (e) {
      print('❌ Error fetching revenue comparison: $e');
      rethrow;
    }
  }

  /// Fetch expense comparison data
  Future<ComparisonChartData> fetchExpenseComparison({
    required TimePeriod timePeriod,
    required Set<ComparisonPeriod> comparisons,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'timePeriod': _timePeriodToString(timePeriod),
        'comparisons': comparisons.map(_comparisonToString).join(','),
      };

      if (timePeriod == TimePeriod.custom && customStartDate != null && customEndDate != null) {
        queryParams['startDate'] = customStartDate.toIso8601String();
        queryParams['endDate'] = customEndDate.toIso8601String();
      }

      final response = await _dio.get(
        '/dashboard/expense-comparison',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      return ComparisonChartData(
        prevData: _parseChartData(data['prevData'] as List<dynamic>),
        nowData: _parseChartData(data['nowData'] as List<dynamic>),
        nextData: _parseChartData(data['nextData'] as List<dynamic>),
      );
    } catch (e) {
      print('❌ Error fetching expense comparison: $e');
      rethrow;
    }
  }

  /// Fetch expense categories data
  Future<List<ExpenseCategoryData>> fetchExpenseCategories({
    required TimePeriod timePeriod,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'timePeriod': _timePeriodToString(timePeriod),
      };

      if (timePeriod == TimePeriod.custom && customStartDate != null && customEndDate != null) {
        queryParams['startDate'] = customStartDate.toIso8601String();
        queryParams['endDate'] = customEndDate.toIso8601String();
      }

      final response = await _dio.get(
        '/dashboard/expense-categories',
        queryParameters: queryParams,
      );

      final data = response.data as List<dynamic>;

      return data.map((item) {
        return ExpenseCategoryData(
          category: item['category'] as String,
          amount: _parseValue(item['amount']),
          color: _parseColor(item['color'] as String),
        );
      }).toList();
    } catch (e) {
      print('❌ Error fetching expense categories: $e');
      rethrow;
    }
  }

  // --- Helper methods (Unchanged logic, just kept for completeness) ---

  String _timePeriodToString(TimePeriod period) {
    switch (period) {
      case TimePeriod.month: return 'month';
      case TimePeriod.year: return 'year';
      case TimePeriod.custom: return 'custom';
    }
  }

  String _comparisonToString(ComparisonPeriod comparison) {
    switch (comparison) {
      case ComparisonPeriod.prev: return 'prev';
      case ComparisonPeriod.now: return 'now';
      case ComparisonPeriod.next: return 'next';
    }
  }

  List<ChartDataPoint> _parseChartData(List<dynamic> data) {
    return data.map((item) {
      return ChartDataPoint(
        label: item['label'] as String,
        value: _parseValue(item['value']),
        date: DateTime.parse(item['date'] as String),
      );
    }).toList();
  }

  double _parseValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is Map) {
      if (value.containsKey('\$numberDecimal')) {
        return double.tryParse(value['\$numberDecimal'].toString()) ?? 0.0;
      }
      if (value.containsKey('\$numberLong')) {
        return double.tryParse(value['\$numberLong'].toString()) ?? 0.0;
      }
      if (value.containsKey('value')) return _parseValue(value['value']);
      if (value.containsKey('amount')) return _parseValue(value['amount']);
      if (value.containsKey('total')) return _parseValue(value['total']);
    }
    return 0.0;
  }

  Color _parseColor(String colorString) {
    final hexColor = colorString.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}