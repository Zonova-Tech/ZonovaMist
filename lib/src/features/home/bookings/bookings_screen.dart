// booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'add_booking_screen.dart';
import 'bookings_provider.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return ListTile(
                title: Text(booking['guest_name'] ?? 'Unknown Guest'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Room(s): ${booking['booked_room_no'] ?? 'N/A'}'),
                    Text(
                      'Check-in: ${booking['checkin_date'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(booking['checkin_date'])) : 'N/A'}',
                    ),
                    Text('Phone: ${booking['phone_no'] ?? 'N/A'}'),
                    Text('Status: ${booking['status'] ?? 'N/A'}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditBookingScreen(booking: booking),
                          ),
                        );
                        if (result == true) {
                          ref.refresh(bookingsProvider);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Booking'),
                            content: Text(
                              'Are you sure you want to delete ${booking['guest_name']}\'s booking?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            final dio = ref.read(dioProvider);
                            await dio.delete('/bookings/${booking['_id']}');
                            ref.refresh(bookingsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking deleted')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBookingScreen()),
          );
          if (result == true) {
            ref.refresh(bookingsProvider);
          }
        },
      ),
    );
  }
}

class EditBookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;

  const EditBookingScreen({super.key, required this.booking});

  @override
  ConsumerState<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends ConsumerState<EditBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _guestNameController;
  late TextEditingController _phoneNoController;
  late TextEditingController _roomNoController;
  late TextEditingController _checkInDateController;
  String? _status; // Allow null initially
  bool _loading = false;

  // Valid statuses for the dropdown
  static const List<String> _validStatuses = ['pending', 'paid', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _guestNameController = TextEditingController(text: widget.booking['guest_name'] ?? '');
    _phoneNoController = TextEditingController(text: widget.booking['phone_no'] ?? '');
    _roomNoController = TextEditingController(text: widget.booking['booked_room_no'] ?? '');
    _checkInDateController = TextEditingController(
      text: widget.booking['checkin_date'] != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.booking['checkin_date']))
          : '',
    );
    // Normalize status to lowercase and validate
    final rawStatus = widget.booking['status']?.toString().toLowerCase();
    _status = _validStatuses.contains(rawStatus) ? rawStatus : 'pending';
    if (rawStatus != null && !_validStatuses.contains(rawStatus)) {
      debugPrint('Invalid status detected: $rawStatus, defaulting to pending');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid status "${widget.booking['status']}", defaulted to pending')),
        );
      });
    }
  }

  Future<void> _updateBooking() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/bookings/${widget.booking['_id']}', data: {
        'guest_name': _guestNameController.text,
        'phone_no': _phoneNoController.text,
        'booked_room_no': _roomNoController.text,
        'checkin_date': _checkInDateController.text,
        'status': _status,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _phoneNoController.dispose();
    _roomNoController.dispose();
    _checkInDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Booking')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _guestNameController,
                decoration: const InputDecoration(labelText: 'Guest Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneNoController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _roomNoController,
                decoration: const InputDecoration(labelText: 'Room Number(s)'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _checkInDateController,
                decoration: const InputDecoration(labelText: 'Check-in Date (YYYY-MM-DD)'),
                validator: (val) {
                  if (val!.isEmpty) return 'Required';
                  try {
                    DateTime.parse(val);
                    return null;
                  } catch (e) {
                    return 'Invalid date format';
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _validStatuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _status = value);
                },
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateBooking,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}