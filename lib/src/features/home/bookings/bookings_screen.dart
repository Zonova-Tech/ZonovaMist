import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/api/api_service.dart';
import '../../../shared/widgets/common_image_manager.dart';
import 'add_booking_screen.dart';
import 'bookings_provider.dart';
import 'edit_booking_screen.dart';
import 'invoice_form_screen.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/audio_recordings_widget.dart';

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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
  }

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
      ref.refresh(bookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking marked as ${newStatus.toUpperCase()}')),
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

  void _showStatusMenu(BuildContext context, WidgetRef ref, Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.pending, color: Colors.orange.shade700),
              title: const Text('Pending'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(context, ref, booking, 'pending');
              },
            ),
            ListTile(
              leading: Icon(Icons.payments, color: Colors.blue.shade700),
              title: const Text('Advance Paid'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(context, ref, booking, 'advance_paid');
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green.shade700),
              title: const Text('Paid'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(context, ref, booking, 'paid');
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.red.shade700),
              title: const Text('Cancelled'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(context, ref, booking, 'cancelled');
              },
            ),
          ],
        ),
      ),
    );
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

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => FilterBottomSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    final searchController = TextEditingController(
      text: ref.read(bookingSearchProvider),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Bookings'),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Search by name, room, or phone',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(bookingSearchProvider.notifier).state = '';
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(bookingSearchProvider.notifier).state = searchController.text;
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  int _calculateNumberOfDays(String? checkinDate, String? checkoutDate) {
    if (checkinDate == null || checkoutDate == null) return 0;
    try {
      final checkin = DateTime.parse(checkinDate);
      final checkout = DateTime.parse(checkoutDate);
      return checkout.difference(checkin).inDays;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final currentFilter = ref.watch(bookingFilterProvider);
    final statusFilter = ref.watch(bookingStatusFilterProvider);
    final searchQuery = ref.watch(bookingSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, ref),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: currentFilter != 'upcoming' || statusFilter != 'advance_paid' || searchQuery.isNotEmpty,
              label: const Text('•'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Active Filter Chips
          if (currentFilter != 'upcoming' || statusFilter != 'advance_paid' || searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.blue.shade50,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (currentFilter != 'upcoming')
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_getFilterLabel(currentFilter)),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            ref.read(bookingFilterProvider.notifier).state = 'upcoming';
                          },
                        ),
                      ),
                    if (statusFilter != 'advance_paid')
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text('Status: ${_getStatusLabel(statusFilter)}'),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            ref.read(bookingStatusFilterProvider.notifier).state = 'advance_paid';
                          },
                        ),
                      ),
                    if (searchQuery.isNotEmpty)
                      Chip(
                        label: Text('Search: $searchQuery'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          ref.read(bookingSearchProvider.notifier).state = '';
                        },
                      ),
                    TextButton.icon(
                      onPressed: () {
                        ref.read(bookingFilterProvider.notifier).state = 'upcoming';
                        ref.read(bookingStatusFilterProvider.notifier).state = 'advance_paid';
                        ref.read(bookingSearchProvider.notifier).state = '';
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
            ),

          // Bookings List
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No bookings found',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final bookingId = booking['_id'] ?? '';
                    final numberOfDays = _calculateNumberOfDays(
                      booking['checkin_date'],
                      booking['checkout_date'],
                    );

                    return Slidable(
                      key: ValueKey('slidable_$bookingId'),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.5,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _updateStatus(context, ref, booking, 'advance_paid'),
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            icon: Icons.payments,
                          ),
                          SlidableAction(
                            onPressed: (_) => _updateStatus(context, ref, booking, 'paid'),
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            icon: Icons.check_circle,
                          ),
                          SlidableAction(
                            onPressed: (_) => _onEdit(context, ref, booking),
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                          ),
                          SlidableAction(
                            onPressed: (_) => _onDelete(context, ref, booking),
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
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
                              // Guest Name and Status
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
                                  GestureDetector(
                                    onTap: () => _showStatusMenu(context, ref, booking),
                                    child: _buildStatusChip(booking['status']),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Main content with two columns
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Room: ${booking['booked_room_no'] ?? 'N/A'}'),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Check-in: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(booking['checkin_date'] ?? DateTime.now().toIso8601String()))} (${numberOfDays}d)',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Right Column
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Total: ${booking['total_price'] ?? 0}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Adults: ${booking['adult_count'] ?? 0}, Kids: ${booking['child_count'] ?? 0}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Images (without label)
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
                              const Divider(height: 1),
                              const SizedBox(height: 12),

                              // Recordings (without label)
                              AudioRecordingsWidget(
                                bookingId: bookingId,
                                recordings: booking['recordings'] ?? [],
                                onRecordingsChanged: () => ref.refresh(bookingsProvider),
                              ),

                              const SizedBox(height: 12),

                              // Send Invoice button
                              SizedBox(
                                width: double.infinity,
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $err'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(bookingsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildStatusChip(String? status) {
    Color color;
    IconData icon;

    switch (status?.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'advance_paid':
        color = Colors.blue;
        icon = Icons.payments;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        icon = Icons.pending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'advance_paid':
        return 'ADVANCE PAID';
      case 'paid':
        return 'PAID';
      case 'cancelled':
        return 'CANCELLED';
      case 'pending':
        return 'PENDING';
      default:
        return (status ?? 'pending').toUpperCase();
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'upcoming':
        return 'Upcoming & Today';
      case 'recent':
        return 'Last 7 Days';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'past':
        return 'Past';
      case 'all':
        return 'All Bookings';
      default:
        return filter;
    }
  }
}

class FilterBottomSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const FilterBottomSheet({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(bookingFilterProvider);
    final statusFilter = ref.watch(bookingStatusFilterProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Bookings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Date Range Filters
          const Text(
            'Date Range',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(context, ref, 'upcoming', 'Upcoming & Today', Icons.arrow_forward, currentFilter),
              _buildFilterChip(context, ref, 'recent', 'Last 7 Days', Icons.calendar_today, currentFilter),
              _buildFilterChip(context, ref, 'week', 'This Week', Icons.date_range, currentFilter),
              _buildFilterChip(context, ref, 'month', 'This Month', Icons.calendar_month, currentFilter),
              _buildFilterChip(context, ref, 'past', 'Past', Icons.history, currentFilter),
              _buildFilterChip(context, ref, 'all', 'All Bookings', Icons.all_inclusive, currentFilter),
            ],
          ),

          const SizedBox(height: 24),

          // Status Filters
          const Text(
            'Payment Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusFilterChip(context, ref, null, 'All Statuses', Icons.filter_list, statusFilter),
              _buildStatusFilterChip(context, ref, 'advance_paid', 'Advance Paid', Icons.payments, statusFilter),
              _buildStatusFilterChip(context, ref, 'paid', 'Paid', Icons.check_circle, statusFilter),
              _buildStatusFilterChip(context, ref, 'pending', 'Pending', Icons.pending, statusFilter),
              _buildStatusFilterChip(context, ref, 'cancelled', 'Cancelled', Icons.cancel, statusFilter),
            ],
          ),

          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String value, String label, IconData icon, String currentFilter) {
    final isSelected = currentFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        ref.read(bookingFilterProvider.notifier).state = value;
      },
    );
  }

  Widget _buildStatusFilterChip(BuildContext context, WidgetRef ref, String? value, String label, IconData icon, String? currentStatus) {
    final isSelected = currentStatus == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        ref.read(bookingStatusFilterProvider.notifier).state = value;
      },
    );
  }
}