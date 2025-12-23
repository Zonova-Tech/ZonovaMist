// lib/src/features/home/dashboard/widgets/profit_comparison_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';import 'package:intl/intl.dart';

class ProfitComparisonChart extends StatelessWidget {
  final Map<int, double> data;

  const ProfitComparisonChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert the map into BarChartGroupData for the chart library
    final barGroups = data.entries.map((entry) {
      final x = entry.key;
      final y = entry.value;
      return BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: y,
            // Use green for profit and red for a loss
            color: y >= 0 ? Colors.green.shade400 : Colors.red.shade400,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          // X-Axis Titles (e.g., days or months)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
              reservedSize: 28,
            ),
          ),
          // Y-Axis Titles (Profit in LKR)
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Format the Y-axis to show "K" for thousands
                final formatter = NumberFormat.compact(locale: 'en_US');
                return Text(formatter.format(value));
              },
              reservedSize: 45,
            ),
          ),
          // Hide top and right titles
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // Customize the tooltip on touch
              return BarTooltipItem(
                'Profit: \n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0).format(rod.toY),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
