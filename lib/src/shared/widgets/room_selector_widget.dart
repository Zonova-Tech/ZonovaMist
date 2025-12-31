// File: lib/src/shared/widgets/room_selector_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/rooms_provider.dart';

/// A reusable widget for selecting hotel rooms using FilterChips
/// with real-time availability checking from backend
class RoomSelectorWidget extends ConsumerWidget {
  final Set<String> selectedRooms;
  final DateTime? checkinDate;
  final DateTime? checkoutDate;
  final String? excludeBookingId;
  final Function(String room, bool selected) onRoomToggle;

  const RoomSelectorWidget({
    super.key,
    required this.selectedRooms,
    required this.checkinDate,
    required this.checkoutDate,
    this.excludeBookingId,
    required this.onRoomToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If dates are not selected, show all rooms from database
    if (checkinDate == null || checkoutDate == null) {
      return _buildWithoutDates(context, ref);
    }

    // If dates are selected, fetch availability from backend
    final params = RoomAvailabilityParams(
      checkinDate: checkinDate!,
      checkoutDate: checkoutDate!,
      excludeBookingId: excludeBookingId,
    );

    final availabilityAsync = ref.watch(availableRoomsProvider(params));

    return availabilityAsync.when(
      data: (availability) => _buildWithAvailability(context, availability),
      loading: () => _buildLoading(context),
      error: (error, stack) => _buildError(context, error.toString()),
    );
  }

  Widget _buildWithoutDates(BuildContext context, WidgetRef ref) {
    final allRoomsAsync = ref.watch(allRoomsProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Room(s) *',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          allRoomsAsync.when(
            data: (rooms) {
              if (rooms.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('No rooms available in the system'),
                      ),
                    ],
                  ),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rooms.map((room) {
                  final isSelected = selectedRooms.contains(room.roomNumber);
                  return FilterChip(
                    label: Text(
                      room.roomNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: null, // Disabled until dates are selected
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.grey.shade400,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Failed to load rooms'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please select check-in and check-out dates first',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Select Room(s) *',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Checking room availability...'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Room(s) *',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Failed to check availability. Please try again.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithAvailability(
      BuildContext context,
      RoomAvailabilityResponse availability,
      ) {
    final allRooms = [...availability.available, ...availability.unavailable];
    allRooms.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

    final unavailableRoomNumbers = availability.unavailable
        .map((room) => room.roomNumber)
        .toSet();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Select Room(s) *',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  '${availability.summary.available} available',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Room FilterChips
          if (allRooms.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('No rooms available in the system'),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allRooms.map((room) {
                final isSelected = selectedRooms.contains(room.roomNumber);
                final isUnavailable = unavailableRoomNumbers.contains(room.roomNumber);

                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        room.roomNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isUnavailable
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (isUnavailable) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.block,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: !isUnavailable
                      ? (selected) => onRoomToggle(room.roomNumber, selected)
                      : null,
                  backgroundColor: isUnavailable
                      ? Colors.grey.shade100
                      : Colors.grey[50],
                  selectedColor: Colors.blue.shade600,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? Colors.blue.shade600
                        : isUnavailable
                        ? Colors.grey.shade300
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),

          // Selected rooms summary
          if (selectedRooms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.meeting_room, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${selectedRooms.join(', ')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Unavailable rooms warning
          if (availability.unavailable.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unavailable: ${unavailableRoomNumbers.join(', ')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}