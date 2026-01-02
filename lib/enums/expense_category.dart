enum ExpenseCategory {
  lightBill,
  waterBill,
  internetBill,
  salary,
  cleaning,
  rent,
  purchases,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.lightBill:
        return 'Light Bill';
      case ExpenseCategory.waterBill:
        return 'Water Bill';
      case ExpenseCategory.internetBill:
        return 'Internet Bill';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.cleaning:
        return 'Cleaning';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.purchases:
        return 'Purchases';
    }
  }
}