import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_service.dart';
import '../../../shared/widgets/common_image_manager.dart';
import 'add_booking_screen.dart';
import 'bookings_provider.dart';
import 'edit_booking_screen.dart';
import 'invoice_form_screen.dart';

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

  Future<void> _viewInvoice(BuildContext context, WidgetRef ref, String bookingId) async {
    try {
      // Get the base URL from your API service
      final dio = ref.read(dioProvider);
      final baseUrl = dio.options.baseUrl.replaceAll('/api', '');
      final url = Uri.parse('$baseUrl/invoice/$bookingId');

      print('🔗 Opening invoice URL: $url');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open invoice at: $url')),
          );
        }
      }
    } catch (e) {
      print('❌ Error opening invoice: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening invoice: $e')),
        );
      }
    }
  }

  Future<void> _sendInvoice(BuildContext context, WidgetRef ref, Map<String, dynamic> booking) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceFormScreen(booking: booking),
      ),
    );
    if (result == true) {
      ref.refresh(bookingsProvider);
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
              final bookingId = booking['_id'] ?? '';

              return Slidable(
                key: ValueKey('slidable_$bookingId'),
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
                  key: ValueKey('card_$bookingId'),
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

                        // Image Manager
                        if (bookingId.isNotEmpty)
                          Hero(
                            tag: 'booking_images_$bookingId',
                            child: Material(
                              color: Colors.transparent,
                              child: CommonImageManager(
                                entityType: 'Booking',
                                entityId: bookingId,
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Invoice Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _sendInvoice(context, ref, booking),
                                icon: const Icon(Icons.send, size: 18),
                                label: const Text('Send Invoice'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _viewInvoice(context, ref, bookingId),
                                icon: const Icon(Icons.receipt_long, size: 18),
                                label: const Text('View Invoice'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue.shade700,
                                  side: BorderSide(color: Colors.blue.shade700),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
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
        heroTag: 'add_booking_fab',
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