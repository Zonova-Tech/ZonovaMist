import 'package:flutter/material.dart';
import 'package:Zonova_Mist/enums/expense_category.dart';

class EditExpensePage extends StatefulWidget {
final Map<String, dynamic> expense;

const EditExpensePage({super.key, required this.expense});

@override
State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
final _formKey = GlobalKey<FormState>();
String? _category;
final _titleCtrl = TextEditingController();
final _amountCtrl = TextEditingController();
DateTime _date = DateTime.now();
final _noteCtrl = TextEditingController();

@override
void initState() {
super.initState();

_category = widget.expense['category']?.toString();
_titleCtrl.text = widget.expense['title']?.toString() ?? '';
_amountCtrl.text = widget.expense['amount']?.toString() ?? '';

final dateStr = widget.expense['date']?.toString();
if (dateStr != null && dateStr.isNotEmpty) {
_date = DateTime.tryParse(dateStr) ?? DateTime.now();
}

_noteCtrl.text = widget.expense['description']?.toString() ??
widget.expense['note']?.toString() ?? '';
}

@override
void dispose() {
_titleCtrl.dispose();
_amountCtrl.dispose();
_noteCtrl.dispose();
super.dispose();
}

Future<void> _selectDate() async {
final d = await showDatePicker(
context: context,
initialDate: _date,
firstDate: DateTime(2000),
lastDate: DateTime.now(),
);
if (d != null) setState(() => _date = d);
}

void _save() {
if (!_formKey.currentState!.validate()) return;
if (_category == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Please select category')),
);
return;
}

final updated = {
'id': widget.expense['id'] ?? widget.expense['_id'],
'category': _category,
'title': _titleCtrl.text.trim(),
'amount': _amountCtrl.text.trim(),
'date': _date.toIso8601String().split('T').first,
'description': _noteCtrl.text.trim(),
};

Navigator.pop(context, updated);
}

@override
Widget build(BuildContext context) {
final categories = ExpenseCategory.values
    .map((e) => e.displayName)
    .toList();

return Scaffold(
appBar: AppBar(title: const Text('Edit Expense')),
body: SingleChildScrollView(
padding: const EdgeInsets.all(16),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
DropdownButtonFormField<String>(
value: categories.contains(_category) ? _category : null,
decoration: const InputDecoration(
labelText: 'Category *',
prefixIcon: Icon(Icons.category),
border: OutlineInputBorder(),
),
items: categories
    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
    .toList(),
onChanged: (v) => setState(() => _category = v),
validator: (v) => v == null ? 'Select category' : null,
),
const SizedBox(height: 16),

TextFormField(
controller: _titleCtrl,
decoration: const InputDecoration(
labelText: 'Title *',
prefixIcon: Icon(Icons.title),
border: OutlineInputBorder(),
),
validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
),
const SizedBox(height: 16),

TextFormField(
controller: _amountCtrl,
decoration: const InputDecoration(
labelText: 'Amount (Rs.) *',
prefixIcon: Icon(Icons.attach_money),
border: OutlineInputBorder(),
),
keyboardType: TextInputType.number,
validator: (v) {
if (v == null || v.isEmpty) return 'Enter amount';
if (double.tryParse(v) == null) return 'Enter valid amount';
return null;
},
),
const SizedBox(height: 16),

InkWell(
onTap: _selectDate,
child: InputDecorator(
decoration: const InputDecoration(
labelText: 'Date *',
prefixIcon: Icon(Icons.calendar_today),
border: OutlineInputBorder(),
),
child: Text(_date.toIso8601String().split('T').first),
),
),
const SizedBox(height: 16),

TextFormField(
controller: _noteCtrl,
decoration: const InputDecoration(
labelText: 'Note (optional)',
prefixIcon: Icon(Icons.note),
border: OutlineInputBorder(),
),
maxLines: 3,
),
const SizedBox(height: 32),

ElevatedButton(
onPressed: _save,
style: ElevatedButton.styleFrom(
backgroundColor: Colors.blue.shade700,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 16),
textStyle: const TextStyle(fontSize: 16),
),
child: const Text('Update Expense'),
),
],
),
),
),
);
}
}
