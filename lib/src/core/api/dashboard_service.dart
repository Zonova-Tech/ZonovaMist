import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/home/dashboard/models/dashboard_models.dart';
import 'package:flutter/material.dart';

class DashboardService {
  static const String baseUrl = 'https://zonova-mist.onrender.com';

  /// Fetch dashboard statistics
  Future<Map<String, StatData>> fetchStats({
    required TimePeriod timePeriod,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'timePeriod': _timePeriodToString(timePeriod),
      };

      if (timePeriod == TimePeriod.custom && customStartDate != null && customEndDate != null) {
        queryParams['startDate'] = customStartDate.toIso8601String();
        queryParams['endDate'] = customEndDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/api/dashboard/stats')
          .replace(queryParameters: queryParams);

      print('📊 Fetching stats from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print('📊 RAW Stats Response: ${response.body}');

        final data = json.decode(response.body) as Map<String, dynamic>;

        print('📊 Parsed Stats Data: $data');

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
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching stats: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Fetch expense comparison data
  Future<ComparisonChartData> fetchRevenueComparison({
    required TimePeriod timePeriod,
    required Set<ComparisonPeriod> comparisons,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'timePeriod': _timePeriodToString(timePeriod),
        'comparisons': comparisons.map(_comparisonToString).join(','),
      };

      if (timePeriod == TimePeriod.custom && customStartDate != null && customEndDate != null) {
        queryParams['startDate'] = customStartDate.toIso8601String();
        queryParams['endDate'] = customEndDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/api/dashboard/revenue-comparison')
          .replace(queryParameters: queryParams);

      print('📊 Fetching revenue comparison from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        print('📊 Revenue response: $data'); // Debug log

        return ComparisonChartData(
          prevData: _parseChartData(data['prevData'] as List<dynamic>),
          nowData: _parseChartData(data['nowData'] as List<dynamic>),
          nextData: _parseChartData(data['nextData'] as List<dynamic>),
        );
      } else {
        throw Exception('Failed to load revenue comparison: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching revenue comparison: $e');
      rethrow;
    }
  }


  Future<ComparisonChartData> fetchExpenseComparison({
    required TimePeriod timePeriod,
    required Set<ComparisonPeriod> comparisons,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'timePeriod': _timePeriodToString(timePeriod),
        'comparisons': comparisons.map(_comparisonToString).join(','),
      };

      if (timePeriod == TimePeriod.custom && customStartDate != null && customEndDate != null) {
        queryParams['startDate'] = customStartDate.toIso8601String();
        queryParams['endDate'] = customEndDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/api/dashboard/expense-comparison')
          .replace(queryParameters: queryParams);

      print('📊 Fetching expense comparison from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        return ComparisonChartData(
          prevData: _parseChartData(data['prevData'] as List<dynamic>),
          nowData: _parseChartData(data['nowData'] as List<dynamic>),
          nextData: _parseChartData(data['nextData'] as List<dynamic>),
        );
      } else {
        throw Exception('Failed to load expense comparison: ${response.statusCode}');
      }
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
      final Map<String, String> queryParams = {
        'timePeriod': _timePeriodToString(timePeriod),
      };

      if (timePeriod == TimePeriod.custom && customStartDate != null && customEndDate != null) {
        queryParams['startDate'] = customStartDate.toIso8601String();
        queryParams['endDate'] = customEndDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/api/dashboard/expense-categories')
          .replace(queryParameters: queryParams);

      print('📊 Fetching expense categories from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;

        print('📊 Expense categories response: $data');

        return data.map((item) {
          return ExpenseCategoryData(
            category: item['category'] as String,
            amount: _parseValue(item['amount']),
            color: _parseColor(item['color'] as String),
          );
        }).toList();
      } else {
        throw Exception('Failed to load expense categories: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching expense categories: $e');
      rethrow;
    }
  }


  // Helper methods
  String _timePeriodToString(TimePeriod period) {
    switch (period) {
      case TimePeriod.month:
        return 'month';
      case TimePeriod.year:
        return 'year';
      case TimePeriod.custom:
        return 'custom';
    }
  }

  String _comparisonToString(ComparisonPeriod comparison) {
    switch (comparison) {
      case ComparisonPeriod.prev:
        return 'prev';
      case ComparisonPeriod.now:
        return 'now';
      case ComparisonPeriod.next:
        return 'next';
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

  /// Helper method to safely parse numeric values
  double _parseValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is Map) {

      if (value.containsKey('\$numberDecimal')) {
        final decimalStr = value['\$numberDecimal'];
        return double.tryParse(decimalStr.toString()) ?? 0.0;
      }
      // Handle MongoDB NumberLong format: {"$numberLong": "123"}
      if (value.containsKey('\$numberLong')) {
        final longStr = value['\$numberLong'];
        return double.tryParse(longStr.toString()) ?? 0.0;
      }
// If it's a nested object, try to find a numeric field
      if (value.containsKey('value')) return _parseValue(value['value']);
      if (value.containsKey('amount')) return _parseValue(value['amount']);
      if (value.containsKey('total')) return _parseValue(value['total']);
    }
    return 0.0;
  }

  Color _parseColor(String colorString) {
    // Convert hex color string to Color
    final hexColor = colorString.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}

