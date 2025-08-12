import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Example placeholder for room list
          Card(
            child: ListTile(
              title: const Text('Room 101 - Deluxe Double'),
              subtitle: const Text('Status: Available • LKR 7500/night'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to room details later
              },
            ),
          ),
        ],
      ),
    );
  }
}
