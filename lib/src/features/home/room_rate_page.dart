import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RoomRatePage extends StatefulWidget {
  const RoomRatePage({super.key});

  @override
  State<RoomRatePage> createState() => _RoomRatePageState();
}

class _RoomRatePageState extends State<RoomRatePage> {
  List<dynamic> rooms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRoomData();
  }

  Future<void> fetchRoomData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/rooms'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ===== Duplicate remove logic =====
        List<Map<String, dynamic>> uniqueRooms = [];
        for (var room in data) {
          if (!uniqueRooms.any((r) =>
          r['maxOccupancy'] == room['maxOccupancy'] &&
              r['pricePerNight'] == room['pricePerNight'])) {
            uniqueRooms.add(room);
          }
        }

        setState(() {
          rooms = uniqueRooms;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Rate Display"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: screenWidth),
            child: Table(
              border: TableBorder.all(color: Colors.black26),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                // ==== Header Row ====
                const TableRow(
                  decoration: BoxDecoration(color: Colors.blueAccent),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Number of Pax",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Number of Rooms",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Total Price (LKR)",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                // ==== Dynamic Data Rows ====
                ...rooms.map((room) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(room['maxOccupancy'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            "1 room (${room['maxOccupancy']} pax)"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                        Text("${room['pricePerNight'].toString()}"),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
