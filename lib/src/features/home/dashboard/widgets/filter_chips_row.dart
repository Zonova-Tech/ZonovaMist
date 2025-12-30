// lib/src/features/home/dashboard/widgets/filter_chips_row.dart

import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';

class FilterChipsRow extends StatelessWidget {
  final TimePeriod timePeriod;
  final Set<ComparisonPeriod> selectedComparisons;
  final Function(TimePeriod) onTimePeriodChanged;
  final Function(ComparisonPeriod) onComparisonToggled;
  final VoidCallback? onCustomDatePressed;

  const FilterChipsRow({
    super.key,
    required this.timePeriod,
    required this.selectedComparisons,
    required this.onTimePeriodChanged,
    required this.onComparisonToggled,
    this.onCustomDatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Period Filter
        Text(
          'Time Period',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTimePeriodChip(
                label: 'Month',
                period: TimePeriod.month,
                context: context,
              ),
              const SizedBox(width: 8),
              _buildTimePeriodChip(
                label: 'Year',
                period: TimePeriod.year,
                context: context,
              ),
              const SizedBox(width: 8),
              _buildCustomChip(context),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Comparison Filter (Single Selection)
        Text(
          'Comparison',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildComparisonChip(
                label: 'Previous',
                period: ComparisonPeriod.prev,
                color: Colors.grey,
                context: context,
              ),
              const SizedBox(width: 8),
              _buildComparisonChip(
                label: 'Current',
                period: ComparisonPeriod.now,
                color: Colors.blue,
                context: context,
              ),
              const SizedBox(width: 8),
              _buildComparisonChip(
                label: 'Next',
                period: ComparisonPeriod.next,
                color: Colors.green,
                context: context,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimePeriodChip({
    required String label,
    required TimePeriod period,
    required BuildContext context,
  }) {
    final isSelected = timePeriod == period;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTimePeriodChanged(period),
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }

  Widget _buildCustomChip(BuildContext context) {
    final isSelected = timePeriod == TimePeriod.custom;
    return InkWell(
      onTap: onCustomDatePressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
              ),
            Text(
              'Custom',
              style: TextStyle(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.calendar_today,
              size: 16,
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChip({
    required String label,
    required ComparisonPeriod period,
    required MaterialColor color,
    required BuildContext context,
  }) {
    // Single selection - check if this is THE selected period
    final isSelected = selectedComparisons.contains(period);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        // Single selection: always set to this period only
        onComparisonToggled(period);
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: color.withAlpha(38),
      checkmarkColor: color,
      showCheckmark: false, // Hide checkmark since we have the colored dot
      labelStyle: TextStyle(
        color: isSelected ? color.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}
