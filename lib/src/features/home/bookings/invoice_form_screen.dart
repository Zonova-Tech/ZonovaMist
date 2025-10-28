import 'package:flutter/material.dart';
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
  final TextEditingController totalController = TextEditingController();
  final TextEditingController foodController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  bool sending = false;

  @override
  void initState() {
    super.initState();
    totalController.text = widget.booking['total_price']?.toString() ?? '0';
  }

  Future<void> _sendInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => sending = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/invoices/send-invoice-sms', data: {
        'bookingId': widget.booking['_id'],
        'total': double.tryParse(totalController.text) ?? 0,
        'food': foodController.text,
        'notes': notesController.text,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice sent successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending invoice: $e')));
      }
    } finally {
      setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Form')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: totalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Amount'),
                validator: (v) => v == null || v.isEmpty ? 'Enter total amount' : null,
              ),
              TextFormField(
                controller: foodController,
                decoration: const InputDecoration(labelText: 'Food Charges'),
              ),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: sending ? null : _sendInvoice,
                child: sending ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Invoice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
