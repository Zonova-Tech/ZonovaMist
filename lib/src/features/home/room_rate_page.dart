
import 'package:flutter/material.dart';

class RoomRatePage extends StatelessWidget {
  const RoomRatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Rate Display"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // horizontal scroll
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: screenWidth,
            ),
            child: Table(
              border: TableBorder.all(color: Colors.black26),
              defaultColumnWidth: const IntrinsicColumnWidth(), // dynamic width
              children: const [
                // ==== Header Row ====
                TableRow(
                  decoration: BoxDecoration(color: Colors.blueAccent),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Number of Pax",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Number of Rooms",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Total Price (LKR)",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                // ==== Data Rows ====
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text("2")),
                  Padding(padding: EdgeInsets.all(8.0), child: Text("1 room (2 pax)")),
                  Padding(padding: EdgeInsets.all(8.0), child: Text("3,500")),
                ]),
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text("3")),
                  Padding(padding: EdgeInsets.all(8.0), child: Text("1 room (3 pax)")),
                  Padding(padding: EdgeInsets.all(8.0), child: Text("4,000")),
                ]),
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text("4")),
                  Padding(padding: EdgeInsets.all(8.0), child: Text("1 room (4 pax)")),
                  Padding(padding: EdgeInsets.all(8.0), child: Text("4,500")),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
