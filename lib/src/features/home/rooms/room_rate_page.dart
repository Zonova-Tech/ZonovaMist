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
  List<Map<String, dynamic>> rooms = [];
  bool isLoading = true;

  int numberOfNights = 1;
  int numberOfRooms = 1;

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  Future<void> fetchRooms() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/rooms');

      if (resp.statusCode == 200) {
        setState(() {
          rooms = List<Map<String, dynamic>>.from(resp.data);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error: $e");
    }
  }

  List<Map<String, dynamic>> duplicateRooms() {
    final List<Map<String, dynamic>> tableRows = [];
    for (var room in rooms) {
      final int roomCount = room['roomCount'] ?? 1;
      for (int i = 0; i < roomCount; i++) {
        tableRows.add(room);
      }
    }
    return tableRows;
  }

  Future<void> _openEditDialog(Map<String, dynamic> room) async {
    final controller = TextEditingController(
      text: (room['pricePerNight'] ?? 0).toString(),
    );

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

    if (result == true) {
      final text = controller.text.trim();
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final dio = ref.read(dioProvider);
        final resp = await dio.patch(
          '/rooms/${room['_id']}',
          data: {"pricePerNight": newPrice},
        );

        Navigator.of(context).pop();

        if (resp.statusCode == 200) {
          setState(() {
            room['pricePerNight'] = newPrice;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Update failed: ${resp.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
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

  Widget _buildPriceBox(Map<String, dynamic> room) {
    final price = room['pricePerNight'] ?? 0;
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

  Widget _buildTable(double minWidth) {
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

/// ADD RoomRateDisplay widget HERE ↓↓↓

class RoomRateDisplay extends StatefulWidget {
  final double basePrice;

  const RoomRateDisplay({super.key, required this.basePrice});

  @override
  State<RoomRateDisplay> createState() => _RoomRateDisplayState();
}

class _RoomRateDisplayState extends State<RoomRateDisplay> {
  DateTime? checkInDate;
  int nights = 1;
  int rooms = 1;
  int people = 1;

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
