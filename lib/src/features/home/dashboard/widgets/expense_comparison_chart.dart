// lib/src/features/home/dashboard/widgets/expense_comparison_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';

class ExpenseComparisonChart extends StatelessWidget {
  final ComparisonChartData data;
  final Set<ComparisonPeriod> selectedComparisons;
  final TimePeriod timePeriod;

  const ExpenseComparisonChart({
    super.key,
    required this.data,
    required this.selectedComparisons,
    required this.timePeriod,
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
              height: 250,
              child: LineChart(
                _buildLineChartData(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (selectedComparisons.contains(ComparisonPeriod.prev))
          _buildLegendItem('Previous', Colors.grey),
        if (selectedComparisons.contains(ComparisonPeriod.prev) &&
            selectedComparisons.length > 1)
          const SizedBox(width: 16),
        if (selectedComparisons.contains(ComparisonPeriod.now))
          _buildLegendItem('Current', Colors.blue),
        if (selectedComparisons.contains(ComparisonPeriod.now) &&
            selectedComparisons.contains(ComparisonPeriod.next))
          const SizedBox(width: 16),
        if (selectedComparisons.contains(ComparisonPeriod.next))
          _buildLegendItem('Next', Colors.green),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData() {
    final lines = <LineChartBarData>[];

    if (selectedComparisons.contains(ComparisonPeriod.prev)) {
      lines.add(_buildLineChartBarData(data.prevData, Colors.grey));
    }
    if (selectedComparisons.contains(ComparisonPeriod.now)) {
      lines.add(_buildLineChartBarData(data.nowData, Colors.blue));
    }
    if (selectedComparisons.contains(ComparisonPeriod.next)) {
      lines.add(_buildLineChartBarData(data.nextData, Colors.green));
    }

    return LineChartData(
      lineBarsData: lines,
      titlesData: FlTitlesData(
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
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _getBottomInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.nowData.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  data.nowData[index].label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _getGridInterval(),
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
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final period = spot.barIndex == 0
                  ? 'Prev'
                  : spot.barIndex == 1
                  ? 'Now'
                  : 'Next';
              return LineTooltipItem(
                '$period\nRs ${spot.y.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<ChartDataPoint> points, Color color) {
    return LineChartBarData(
      spots: points
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.value))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  double _getBottomInterval() {
    final count = data.nowData.length;
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 31) return 5;
    return 1;
  }

  double _getGridInterval() {
    double maxValue = 0;
    if (selectedComparisons.contains(ComparisonPeriod.prev)) {
      maxValue = data.prevData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    }
    if (selectedComparisons.contains(ComparisonPeriod.now)) {
      final nowMax = data.nowData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
      maxValue = nowMax > maxValue ? nowMax : maxValue;
    }
    if (selectedComparisons.contains(ComparisonPeriod.next)) {
      final nextMax = data.nextData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
      maxValue = nextMax > maxValue ? nextMax : maxValue;
    }
    return maxValue / 5;
  }

  String _formatValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}