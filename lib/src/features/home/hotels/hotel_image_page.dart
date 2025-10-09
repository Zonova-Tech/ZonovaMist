import 'package:Zonova_Mist/src/shared/widgets/common_image_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



class HotelDetailsScreen extends ConsumerWidget {
  final Map<String, dynamic> hotel;

  const HotelDetailsScreen({super.key, required this.hotel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = List<String>.from(hotel['photos'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hotel Details - ${hotel['name'] ?? 'Hotel'}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel['name'] ?? 'Hotel Name',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('City: ${hotel['location']?['city'] ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Star Rating: ${hotel['starRating'] ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Price Range: LKR ${hotel['priceRange'] ?? '-'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CommonImageManager(
              entityType: 'Hotel', // Capital H
              entityId: hotel['_id'],
            ),
          ],
        ),
      ),
    );
  }
}
