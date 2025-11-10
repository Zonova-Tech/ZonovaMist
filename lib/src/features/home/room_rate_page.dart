import 'package:flutter/material.dart';

class RoomRatePage extends StatefulWidget {
  const RoomRatePage({super.key});

  @override
  State<RoomRatePage> createState() => _RoomRatePageState();
}

class _RoomRatePageState extends State<RoomRatePage> {
  // Sample static data
  List<Map<String, dynamic>> rooms = [
    {"maxOccupancy": 2, "pricePerNight": 12000},
    {"maxOccupancy": 4, "pricePerNight": 18000},
    {"maxOccupancy": 6, "pricePerNight": 25000},
  ];

  final bool isAdmin = true;

  Future<void> _openEditDialog(int index) async {
    final current = rooms[index];
    final controller = TextEditingController(
      text: (current['pricePerNight'] ?? 0).toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('1 Room 2 Pax'),
          content: SizedBox(
            width: 300, // fixed width for responsive dialog
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'New Total Price (LKR)',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 90, // small but same width
              height: 36,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              height: 36,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final text = controller.text.trim();
      if (text.isEmpty || double.tryParse(text) == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid number')),
        );
        return;
      }

      final value = double.parse(text);
      setState(() {
        rooms[index]['pricePerNight'] = value;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total price updated (local only)')),
      );
    }
  }

  Widget _buildPriceBox(int index) {
    final price = rooms[index]['pricePerNight'] ?? 0;
    return GestureDetector(
      onTap: isAdmin ? () => _openEditDialog(index) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LKR ${price.toString()}',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 6),
              Icon(Icons.edit, size: 14, color: Colors.blue.shade700),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTable(double minWidth) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          defaultColumnWidth: const IntrinsicColumnWidth(),
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
                    "Number of Rooms",
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
                    "Total Price (LKR)",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            ...List.generate(rooms.length, (index) {
              final room = rooms[index];
              return TableRow(
                decoration: const BoxDecoration(color: Colors.white),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                    child: Text(
                      room['maxOccupancy'].toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                    child: Text(
                      "1 room",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                    child: Center(child: _buildPriceBox(index)),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Number of Pax',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700),
                    ),
                    Text(
                      room['maxOccupancy'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '# Rooms',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700),
                    ),
                    const Text('1 room'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Price (LKR)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700),
                    ),
                    _buildPriceBox(index),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Rate Display"),
        backgroundColor: Colors.yellow.shade700,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return _buildCardList();
          } else {
            return _buildTable(screenWidth);
          }
        }),
      ),
    );
  }
}
