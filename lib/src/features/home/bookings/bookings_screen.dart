// bookings_screen.dart
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
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
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
                            booking['guest_name'] ?? 'Unknown Guest',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Row(
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
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.meeting_room, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text("Room(s): ${booking['booked_room_no'] ?? 'N/A'}"),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Check-in: ${booking['checkin_date'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(booking['checkin_date'])) : 'N/A'}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('Phone: ${booking['phone_no'] ?? 'N/A'}'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Status: ${booking['status'] ?? 'N/A'}',
                            style: TextStyle(
                              color: (booking['status'] == 'paid')
                                  ? Colors.green
                                  : (booking['status'] == 'pending')
                                  ? Colors.orange
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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

class EditBookingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const EditBookingScreen({super.key, required this.booking});

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  late TextEditingController clientNameController;
  late TextEditingController roomNoController;
  late TextEditingController dateController;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    clientNameController =
        TextEditingController(text: widget.booking['clientName']);
    roomNoController =
        TextEditingController(text: widget.booking['roomNo'].toString());
    dateController = TextEditingController(text: widget.booking['date']);
    notesController =
        TextEditingController(text: widget.booking['notes'] ?? '');
  }

  @override
  void dispose() {
    clientNameController.dispose();
    roomNoController.dispose();
    dateController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void saveBooking() {
    final updatedBooking = {
      'clientName': clientNameController.text,
      'roomNo': roomNoController.text,
      'date': dateController.text,
      'notes': notesController.text,
    };

    Navigator.pop(context, updatedBooking);
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        TextInputType inputType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Booking"),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField("Client Name", clientNameController),
            _buildTextField("Room No", roomNoController,
                inputType: TextInputType.number),
            _buildTextField("Booking Date", dateController,
                inputType: TextInputType.datetime),
            _buildTextField("Notes", notesController, maxLines: 3),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Save Booking",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
