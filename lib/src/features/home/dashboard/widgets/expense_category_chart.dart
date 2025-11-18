// lib/src/features/home/dashboard/widgets/expense_category_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';

class ExpenseCategoryChart extends StatelessWidget {
  final List<ExpenseCategoryData> data;

  const ExpenseCategoryChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegend(),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                _buildBarChartData(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: data.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.category,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  BarChartData _buildBarChartData() {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _getMaxY(),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${data[group.x.toInt()].category}\nRs ${rod.toY.toStringAsFixed(0)}',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Transform.rotate(
                  angle: -0.5,
                  child: Text(
                    data[index].category,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Text(
                'Rs ${_formatValue(value)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _getMaxY() / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      barGroups: _buildBarGroups(),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return data.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.amount,
            color: entry.value.color,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: Colors.grey.shade100,
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY() {
    final maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    return (maxAmount * 1.2).ceilToDouble();
  }

  String _formatValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}