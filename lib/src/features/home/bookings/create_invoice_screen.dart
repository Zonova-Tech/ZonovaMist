import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String guestName;
  final String phone;

  const CreateInvoiceScreen({
    super.key,
    required this.bookingId,
    required this.guestName,
    required this.phone,
  });

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _roomChargeController = TextEditingController();
  final TextEditingController _foodChargeController = TextEditingController();
  final TextEditingController _otherChargeController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();

  bool _isSending = false;

  Future<void> _sendInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/invoices/send-invoice-sms', data: {
        "bookingId": widget.bookingId,
        "total": _totalController.text,
        "foodCharge": _foodChargeController.text,
        "roomCharge": _roomChargeController.text,
        "otherCharge": _otherChargeController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice sent to ${widget.phone}!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending invoice: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Guest: ${widget.guestName}', style: const TextStyle(fontSize: 18)),
              Text('Phone: ${widget.phone}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _roomChargeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Room Charge'),
              ),
              TextFormField(
                controller: _foodChargeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Food Charge'),
              ),
              TextFormField(
                controller: _otherChargeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Other Charges'),
              ),
              TextFormField(
                controller: _totalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total'),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: _isSending ? null : _sendInvoice,
                icon: const Icon(Icons.send),
                label: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send Invoice via SMS'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
