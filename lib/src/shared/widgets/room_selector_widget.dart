import 'package:flutter/material.dart';

/// A reusable widget for selecting hotel rooms using FilterChips
/// with real-time availability checking
class RoomSelectorWidget extends StatelessWidget {
  final List<String> allRooms;
  final Set<String> selectedRooms;
  final Set<String> unavailableRooms;
  final bool isCheckingAvailability;
  final DateTime? checkinDate;
  final DateTime? checkoutDate;
  final Function(String room, bool selected) onRoomToggle;

  const RoomSelectorWidget({
    super.key,
    required this.allRooms,
    required this.selectedRooms,
    required this.unavailableRooms,
    required this.isCheckingAvailability,
    required this.checkinDate,
    required this.checkoutDate,
    required this.onRoomToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with loading indicator
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
              if (isCheckingAvailability) ...[
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
            ],
          ),
          const SizedBox(height: 12),

          // Room FilterChips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allRooms.map((room) {
              final isSelected = selectedRooms.contains(room);
              final isUnavailable = unavailableRooms.contains(room);
              final canSelect = checkinDate != null &&
                  checkoutDate != null &&
                  !isUnavailable;

              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      room,
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
                onSelected: canSelect
                    ? (selected) => onRoomToggle(room, selected)
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

          // Date selection reminder
          if (checkinDate == null || checkoutDate == null) ...[
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
          if (unavailableRooms.isNotEmpty) ...[
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
                      'Unavailable: ${unavailableRooms.join(', ')}',
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