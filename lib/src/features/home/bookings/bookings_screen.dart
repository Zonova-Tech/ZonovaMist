import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/api/api_service.dart';
import '../../../shared/widgets/common_image_manager.dart';
import 'add_booking_screen.dart';
import 'bookings_provider.dart';
import 'edit_booking_screen.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  Future<void> _onEdit(BuildContext context, WidgetRef ref, Map<String, dynamic> booking) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBookingScreen(booking: Map<String, dynamic>.from(booking)),
      ),
    );
    if (result == true) {
      ref.refresh(bookingsProvider);
    }
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking'),
        content: Text('Are you sure you want to delete ${booking['guest_name']}\'s booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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
  }

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
              return Slidable(
                key: ValueKey(booking['_id']),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.4,
                  children: [
                    SlidableAction(
                      onPressed: (_) => _onEdit(context, ref, booking),
                      backgroundColor: Colors.blue.shade500,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                    SlidableAction(
                      onPressed: (_) => _onDelete(context, ref, booking),
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: Card(
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
                            Expanded(
                              child: Text(
                                booking['guest_name'] ?? 'Unknown Guest',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Room: ${booking['booked_room_no'] ?? 'N/A'}'),
                        Text('Check-in: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(booking['checkin_date'] ?? DateTime.now().toIso8601String()))}'),
                        Text('Check-out: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(booking['checkout_date'] ?? DateTime.now().toIso8601String()))}'),
                        Text('Status: ${booking['status'] ?? 'N/A'}'),
                        const SizedBox(height: 12),
                        if (booking['_id'] != null && booking['_id'].isNotEmpty)
                        CommonImageManager(
                          entityType: 'Booking',
                          entityId: booking['_id'],
                        ),
                      ],
                    ),
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBookingScreen()),
          );
          if (result == true) {
            ref.refresh(bookingsProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}