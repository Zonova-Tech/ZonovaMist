/// Helper class to handle MongoDB Decimal128 values
class DecimalHelper {
  /// Safely converts Decimal128 or any numeric value to double
  static double? toDouble(dynamic value) {
    if (value == null) return null;

    try {
      // Handle Decimal128 format from MongoDB: { "$numberDecimal": "123.45" }
      if (value is Map && value.containsKey('\$numberDecimal')) {
        return double.tryParse(value['\$numberDecimal'].toString());
      }

      // Handle regular number
      if (value is num) {
        return value.toDouble();
      }

      // Handle string
      if (value is String) {
        return double.tryParse(value);
      }

      return null;
    } catch (e) {
      print('Error converting to double: $e');
      return null;
    }
  }

  /// Formats a Decimal128 or numeric value as currency
  static String formatCurrency(dynamic value, {String symbol = '\$', int decimals = 2}) {
    final doubleValue = toDouble(value);
    if (doubleValue == null) return 'N/A';
    return '$symbol${doubleValue.toStringAsFixed(decimals)}';
  }

  /// Formats a Decimal128 or numeric value as a plain string
  static String formatNumber(dynamic value, {int decimals = 2}) {
    final doubleValue = toDouble(value);
    if (doubleValue == null) return '';
    return doubleValue.toStringAsFixed(decimals);
  }

  /// Converts to string for editing (without currency symbol)
  static String toEditableString(dynamic value) {
    final doubleValue = toDouble(value);
    if (doubleValue == null) return '';
    // Remove trailing zeros for cleaner editing
    return doubleValue.toString();
  }
}