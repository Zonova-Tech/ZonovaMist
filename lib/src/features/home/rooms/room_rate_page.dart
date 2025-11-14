import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RoomRatePage extends StatefulWidget {
  const RoomRatePage({super.key});

  @override
  State<RoomRatePage> createState() => _RoomRatePageState();
}

class _RoomRatePageState extends State<RoomRatePage> {
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
      final response = await http.get(
        Uri.parse("https://zonova-mist.onrender.com/api/rooms"),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          rooms = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        debugPrint("Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching data: $e");
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
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 100,
              height: 36,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
            ),
            SizedBox(width: 9),
            SizedBox(
              width: 100,
              height: 36,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
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
        final response = await http.patch(
          Uri.parse("https://zonova-mist.onrender.com/api/rooms/${room['_id']}"),
          headers: {"Content-Type": "application/json"},
          body: json.encode({"pricePerNight": newPrice}),
        );

        Navigator.of(context).pop();

        if (response.statusCode == 200) {
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
              content: Text('Update failed: ${response.statusCode}'),
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
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LKR $totalPrice',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Icon(Icons.edit, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(double minWidth) {
    final tableRows = duplicateRooms();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: minWidth > 280 ? minWidth : 280,
        height: 350,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(90),
            1: FixedColumnWidth(60),
            2: FixedColumnWidth(130),
          },
          border: TableBorder.all(color: Colors.grey.shade300),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.yellow.shade600),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                  child: Text(
                    "Number of Pax",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                  child: Text(
                    "# Rooms",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                  child: Text(
                    "Total Price",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            ...tableRows.map((room) {
              return TableRow(
                decoration: const BoxDecoration(color: Colors.white),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    alignment: Alignment.center,
                    child: Text(room['maxOccupancy'].toString()),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    alignment: Alignment.center,
                    child: const Text('1'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    alignment: Alignment.center,
                    child: _buildPriceBox(room),
                  ),
                ],
              );
            }).toList(),
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
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : rooms.isEmpty
          ? const Center(child: Text("No rooms found"))
          : SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: _buildTable(screenWidth),
        ),
      ),
    );
  }
}