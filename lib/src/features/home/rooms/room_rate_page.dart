import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';


class RoomRatePage extends ConsumerStatefulWidget {
  const RoomRatePage({super.key});

  @override
  ConsumerState<RoomRatePage> createState() => _RoomRatePageState();
}

class _RoomRatePageState extends ConsumerState<RoomRatePage> {
  // List of rooms fetched from the API
  List<Map<String, dynamic>> rooms = [];

  // Loading state indicator for API calls
  bool isLoading = true;

  // Number of nights for pricing calculation
  int numberOfNights = 1;

  // Number of rooms for pricing calculation
  int numberOfRooms = 1;

  @override
  void initState() {
    super.initState();
    // Fetch rooms data when page loads
    fetchRooms();
  }

  /// Fetch all rooms from the API
  /// Updates the rooms list and manages loading state
  Future<void> fetchRooms() async {
    try {
      final dio = ref.read(dioProvider);

      // Call API to get rooms data
      final resp = await dio.get('/rooms');

      if (resp.statusCode == 200) {
        // Update state with fetched rooms
        setState(() {
          rooms = List<Map<String, dynamic>>.from(resp.data);
          isLoading = false;
        });
      } else {
        // Handle non-200 responses
        setState(() => isLoading = false);
      }
    } catch (e) {
      // Handle errors and stop loading
      setState(() => isLoading = false);
      debugPrint("Error: $e");
    }
  }

  /// Duplicate room entries based on room count
  /// Returns a list where each room appears 'roomCount' times in the table
  /// This allows displaying multiple rows for rooms with count > 1
  List<Map<String, dynamic>> duplicateRooms() {
    final List<Map<String, dynamic>> tableRows = [];
    for (var room in rooms) {
      final int roomCount = room['roomCount'] ?? 1;
      // Add room entry multiple times based on room count
      for (int i = 0; i < roomCount; i++) {
        tableRows.add(room);
      }
    }
    return tableRows;
  }

  /// Open dialog to edit room price
  /// Shows a dialog with text field for price input
  /// Validates input and updates room price via API on save
  Future<void> _openEditDialog(Map<String, dynamic> room) async {
    // Initialize controller with current price
    final controller = TextEditingController(
      text: (room['pricePerNight'] ?? 0).toString(),
    );

    // Show edit dialog and wait for result
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Room ${room["roomNumber"]}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            autofocus: true,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 100,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        );
      },
    );

    // Process the result if user clicked Save
    if (result == true) {
      final text = controller.text.trim();

      // Validate the input
      if (text.isEmpty || double.tryParse(text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a valid number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newPrice = double.parse(text);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final dio = ref.read(dioProvider);

        // Update room price via API
        final resp = await dio.patch(
          '/rooms/${room['_id']}',
          data: {"pricePerNight": newPrice},
        );

        // Close loading indicator
        Navigator.of(context).pop();

        if (resp.statusCode == 200) {
          // Update local state with new price
          setState(() {
            room['pricePerNight'] = newPrice;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error message for failed update
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Update failed: ${resp.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle API errors
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating room: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build price display box with tap-to-edit functionality
  /// Calculates and displays total price based on nights and rooms
  Widget _buildPriceBox(Map<String, dynamic> room) {
    final price = room['pricePerNight'] ?? 0;
    // Calculate total price: base price × nights × rooms
    final totalPrice = price * numberOfNights * numberOfRooms;

    return GestureDetector(
      onTap: () => _openEditDialog(room),
      child: Text(
        'LKR $totalPrice',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Build the room rate table with all room entries
  /// Table displays: Number of Pax, Number of Rooms, and Total Price
  Widget _buildTable(double minWidth) {
    // Get duplicated room entries for table rows
    final tableRows = duplicateRooms();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: minWidth > 280 ? minWidth : 280,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(90),
            1: FixedColumnWidth(60),
            2: FixedColumnWidth(130),
          },
          border: TableBorder.all(color: Colors.grey),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Table header row
            TableRow(
              decoration: BoxDecoration(color: Colors.yellow.shade600),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Number of Pax",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "# Rooms",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Total Price",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            // Table data rows - one row per room entry
            ...tableRows.map((room) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(
                      room['maxOccupancy'].toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Text('1', textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: _buildPriceBox(room),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Rate Display"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : rooms.isEmpty
          ? const Center(child: Text("No rooms found"))
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(child: _buildTable(screenWidth)),
      ),
    );
  }
}



/// Room Rate Display Widget - Shows pricing calculator for a single room
/// Allows users to select check-in date, nights, rooms, and number of people
/// Calculates total rate including extra person charges
class RoomRateDisplay extends StatefulWidget {
  // Base price per night for the room
  final double basePrice;

  const RoomRateDisplay({super.key, required this.basePrice});

  @override
  State<RoomRateDisplay> createState() => _RoomRateDisplayState();
}

class _RoomRateDisplayState extends State<RoomRateDisplay> {
  // Selected check-in date
  DateTime? checkInDate;

  // Number of nights to stay
  int nights = 1;

  // Number of rooms to book
  int rooms = 1;

  // Number of people staying
  int people = 1;

  /// Calculate total room rate
  /// Formula: (basePrice × nights × rooms) + (extra person charge × nights × rooms)
  /// Extra person charge is LKR 20 per person per night
  double calculateRate() {
    double extraPersonRate = 20;
    return (widget.basePrice * nights * rooms) +
        ((people - 1) * extraPersonRate * nights * rooms);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Check-in date picker
            Row(
              children: [
                const Text('Check-in: '),
                TextButton(
                  child: Text(checkInDate != null
                      ? DateFormat('MMM dd, yyyy').format(checkInDate!)
                      : 'Select Date'),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        checkInDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),

            // Number of nights selector
            Row(
              children: [
                const Text('Nights: '),
                DropdownButton<int>(
                  value: nights,
                  items: List.generate(30, (index) => index + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (val) => setState(() => nights = val!),
                ),
              ],
            ),

            // Number of rooms selector
            Row(
              children: [
                const Text('Rooms: '),
                DropdownButton<int>(
                  value: rooms,
                  items: List.generate(10, (index) => index + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (val) => setState(() => rooms = val!),
                ),
              ],
            ),

            // Number of people selector
            Row(
              children: [
                const Text('People: '),
                DropdownButton<int>(
                  value: people,
                  items: List.generate(10, (index) => index + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (val) => setState(() => people = val!),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Display calculated total price
            Text(
              'Total Price: LKR ${calculateRate().toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}