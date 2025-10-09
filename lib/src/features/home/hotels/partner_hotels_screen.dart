import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/auth/hotels_provider.dart';
import '../../../core/api/api_service.dart';
import '../../../shared/widgets/common_image_manager.dart';
import 'add_hotel_screen.dart';
import 'edit_hotel_screen.dart';

class PartnerHotelsScreen extends ConsumerStatefulWidget {
  const PartnerHotelsScreen({super.key});

  @override
  ConsumerState<PartnerHotelsScreen> createState() => _PartnerHotelsScreenState();
}

class _PartnerHotelsScreenState extends ConsumerState<PartnerHotelsScreen> {
  Future<void> _onEdit(Map<String, dynamic> hotel) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditHotelScreen(hotel: Map<String, dynamic>.from(hotel))),
    );
    if (result == true && mounted) {
      ref.refresh(hotelsProvider);
    }
  }

  Future<void> _onDelete(Map<String, dynamic> hotel) async {
    final hotelId = hotel['_id'] as String;
    final hotelName = hotel['name'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Hotel'),
        content: Text('Are you sure you want to delete $hotelName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dio = ref.read(dioProvider);
        final resp = await dio.delete('/partner-hotels/$hotelId');

        if ((resp.statusCode ?? 500) >= 200 && (resp.statusCode ?? 500) < 300) {
          if (mounted) {
            ref.refresh(hotelsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hotel deleted')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete: ${resp.statusCode}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelsAsync = ref.watch(hotelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Hotels'), backgroundColor: Colors.blueAccent),
      body: hotelsAsync.when(
        data: (hotels) {
          if (hotels.isEmpty) {
            return const Center(child: Text('No partner hotels found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              final hotel = hotels[index] as Map<String, dynamic>;
              final hotelId = hotel['_id'] as String? ?? '';

              return Slidable(
                key: ValueKey(hotelId),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.4,
                  children: [
                    SlidableAction(
                      onPressed: (_) => _onEdit(hotel),
                      backgroundColor: Colors.blue.shade500,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                    SlidableAction(
                      onPressed: (_) => _onDelete(hotel),
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.hotel, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hotel['name'] ?? 'Unnamed Hotel',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('Location: ${hotel['location'] ?? 'N/A'}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('Rating: ${hotel['rating'] ?? 'N/A'}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('Price: LKR ${hotel['price'] ?? 'N/A'}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CommonImageManager(
                          entityType: 'Hotel',
                          entityId: hotelId,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddHotelScreen()),
          );
          if (result == true) {
            ref.refresh(hotelsProvider);
          }
        },
      ),
    );
  }
}
