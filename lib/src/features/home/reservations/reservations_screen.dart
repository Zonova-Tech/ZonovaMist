import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'reservations_provider.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart';
import '../../../shared/widgets/app_drawer.dart';


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
        builder: (context, scrollController) => ReservationFilterBottomSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    final searchController = TextEditingController(
      text: ref.read(reservationSearchProvider),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Reservations'),
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
              ref.read(reservationSearchProvider.notifier).state = '';
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(reservationSearchProvider.notifier).state = searchController.text;
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(reservationsProvider);
    final currentFilter = ref.watch(reservationFilterProvider);
    final statusFilter = ref.watch(reservationStatusFilterProvider);
    final searchQuery = ref.watch(reservationSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservations"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, ref),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: currentFilter != 'upcoming' || statusFilter != 'pending' || searchQuery.isNotEmpty,
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
          if (currentFilter != 'upcoming' || statusFilter != 'pending' || searchQuery.isNotEmpty)
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
                            ref.read(reservationFilterProvider.notifier).state = 'upcoming';
                          },
                        ),
                      ),
                    if (statusFilter != 'pending')
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text('Status: ${_getStatusLabel(statusFilter)}'),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            ref.read(reservationStatusFilterProvider.notifier).state = 'pending';
                          },
                        ),
                      ),
                    if (searchQuery.isNotEmpty)
                      Chip(
                        label: Text('Search: $searchQuery'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          ref.read(reservationSearchProvider.notifier).state = '';
                        },
                      ),
                    TextButton.icon(
                      onPressed: () {
                        ref.read(reservationFilterProvider.notifier).state = 'upcoming';
                        ref.read(reservationStatusFilterProvider.notifier).state = 'pending';
                        ref.read(reservationSearchProvider.notifier).state = '';
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
            ),

          // Reservations List
          Expanded(
            child: reservationsAsync.when(
              data: (reservations) {
                if (reservations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No reservations found',
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
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final booking = reservations[index];
                    return Slidable(
                      key: ValueKey(booking['_id']),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.4,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _updateStatus(context, ref, booking, "advance_paid"),
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            icon: Icons.payments,
                          ),
                          SlidableAction(
                            onPressed: (_) => _updateStatus(context, ref, booking, "paid"),
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            icon: Icons.check_circle,
                          ),
                          SlidableAction(
                            onPressed: (_) => _updateStatus(context, ref, booking, "cancelled"),
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            icon: Icons.cancel,
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
                                  GestureDetector(
                                    onTap: () => _showStatusMenu(context, ref, booking),
                                    child: _buildStatusChip(booking['status']),
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
                      onPressed: () => ref.refresh(reservationsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      case 'today':
        return 'Today Only';
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

class ReservationFilterBottomSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const ReservationFilterBottomSheet({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(reservationFilterProvider);
    final statusFilter = ref.watch(reservationStatusFilterProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Reservations',
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
              _buildFilterChip(context, ref, 'today', 'Today Only', Icons.today, currentFilter),
              _buildFilterChip(context, ref, 'recent', 'Last 7 Days', Icons.calendar_today, currentFilter),
              _buildFilterChip(context, ref, 'week', 'This Week', Icons.date_range, currentFilter),
              _buildFilterChip(context, ref, 'month', 'This Month', Icons.calendar_month, currentFilter),
              _buildFilterChip(context, ref, 'past', 'Past', Icons.history, currentFilter),
              _buildFilterChip(context, ref, 'all', 'All Reservations', Icons.all_inclusive, currentFilter),
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
              _buildStatusFilterChip(context, ref, 'pending', 'Pending', Icons.pending, statusFilter),
              _buildStatusFilterChip(context, ref, 'advance_paid', 'Advance Paid', Icons.payments, statusFilter),
              _buildStatusFilterChip(context, ref, 'paid', 'Paid', Icons.check_circle, statusFilter),
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
        ref.read(reservationFilterProvider.notifier).state = value;
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
        ref.read(reservationStatusFilterProvider.notifier).state = value;
      },
    );
  }
}