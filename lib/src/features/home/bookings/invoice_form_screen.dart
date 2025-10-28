import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;
  const InvoiceFormScreen({super.key, required this.booking});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController roomChargesController = TextEditingController();
  final TextEditingController foodController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  bool sending = false;

  double get roomCharges => double.tryParse(roomChargesController.text) ?? 0;
  double get foodCharges => double.tryParse(foodController.text) ?? 0;
  double get advanceAmount => _parseDecimal(widget.booking['advance_amount']) ?? 0;
  double get totalAmount => roomCharges + foodCharges;
  double get balanceDue => totalAmount - advanceAmount;

  @override
  void initState() {
    super.initState();
    // Initialize with existing values or defaults
    final existingTotal = _parseDecimal(widget.booking['total_price']) ?? 0;
    final existingFood = _parseDecimal(widget.booking['food']) ?? 0;
    final existingRoom = existingTotal - existingFood;

    roomChargesController.text = existingRoom > 0 ? existingRoom.toStringAsFixed(2) : '';
    foodController.text = existingFood > 0 ? existingFood.toStringAsFixed(2) : '0';
    notesController.text = widget.booking['special_notes']?.toString() ?? '';

    // Add listeners to update calculations
    roomChargesController.addListener(() => setState(() {}));
    foodController.addListener(() => setState(() {}));
  }

  double? _parseDecimal(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is Map && value.containsKey('\$numberDecimal')) {
      return double.tryParse(value['\$numberDecimal'].toString());
    }
    return double.tryParse(value.toString());
  }

  Future<void> _sendInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total amount must be greater than 0')),
      );
      return;
    }

    setState(() => sending = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/invoices/send-invoice-sms', data: {
        'bookingId': widget.booking['_id'],
        'total': totalAmount,
        'food': foodCharges,
        'notes': notesController.text.trim(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Invoice sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error sending invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    roomChargesController.dispose();
    foodController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Invoice'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guest Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            widget.booking['guest_name'] ?? 'Guest',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Room: ${widget.booking['booked_room_no'] ?? 'N/A'}'),
                      Text('Phone: ${widget.booking['phone_no'] ?? 'N/A'}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Charges Section
              const Text(
                'Charges',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Room Charges
              TextFormField(
                controller: roomChargesController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Room Charges (Rs.)',
                  prefixIcon: const Icon(Icons.bed),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter room charges';
                  final val = double.tryParse(v);
                  if (val == null || val < 0) return 'Invalid amount';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Food Charges
              TextFormField(
                controller: foodController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Food & Beverages (Rs.)',
                  prefixIcon: const Icon(Icons.restaurant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final val = double.tryParse(v);
                  if (val == null || val < 0) return 'Invalid amount';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Calculation Summary Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryRow('Room Charges:', roomCharges),
                      const Divider(),
                      _buildSummaryRow('Food Charges:', foodCharges),
                      const Divider(),
                      _buildSummaryRow(
                        'Subtotal:',
                        totalAmount,
                        isBold: true,
                      ),
                      const Divider(thickness: 2),
                      _buildSummaryRow(
                        'Advance Paid:',
                        advanceAmount,
                        color: Colors.green,
                      ),
                      const Divider(thickness: 2),
                      _buildSummaryRow(
                        'Balance Due:',
                        balanceDue,
                        isBold: true,
                        isLarge: true,
                        color: balanceDue > 0 ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Notes
              const Text(
                'Additional Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Special notes or instructions',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: 'e.g., Payment method, special requests...',
                ),
              ),

              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: sending ? null : _sendInvoice,
                  icon: sending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.send),
                  label: Text(
                    sending ? 'Sending...' : 'Send Invoice via SMS',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info text
              Center(
                child: Text(
                  'Invoice will be sent to ${widget.booking['phone_no'] ?? 'guest'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      double amount, {
        bool isBold = false,
        bool isLarge = false,
        Color? color,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isLarge ? 20 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}