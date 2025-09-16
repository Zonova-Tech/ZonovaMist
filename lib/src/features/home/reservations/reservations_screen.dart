import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/reservations_provider.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart';

class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  Future<void> _updateStatus(
      BuildContext context,
      WidgetRef ref,
      Map<String, dynamic> booking,
      String newStatus,
      ) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/bookings/${booking['_id']}', data: {
        'status': newStatus,
      });
      ref.refresh(reservationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking marked as $newStatus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(reservationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Reservations")),
      body: reservationsAsync.when(
        data: (reservations) {
          if (reservations.isEmpty) {
            return const Center(child: Text("No reservations found."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final booking = reservations[index];
              return Slidable(
                key: ValueKey(booking['_id']),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.6,
                  children: [
                    SlidableAction(
                      onPressed: (_) => _updateStatus(context, ref, booking, "paid"),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      icon: Icons.check,
                      label: 'Mark Paid',
                    ),
                    SlidableAction(
                      onPressed: (_) => _updateStatus(context, ref, booking, "cancelled"),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.block,
                      label: 'Deny Entry',
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
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
