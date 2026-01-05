import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:Zonova_Mist/src/features/home/assets/models/asset_model.dart';
import 'package:Zonova_Mist/src/features/home/assets/asset_details_screen.dart';
import 'package:Zonova_Mist/src/features/home/assets/providers/asset_provider.dart';

class AssetGroupScreen extends ConsumerWidget { // Changed to ConsumerWidget
  final String groupName;
  final List<AssetModel> assets;

  const AssetGroupScreen({
    super.key,
    required this.groupName,
    required this.assets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Added WidgetRef
    final assetsState = ref.watch(assetsProvider);

    // Find the latest version of the assets for this group from the provider state
    final currentGroupAssets = assetsState.when(
      data: (allAssets) => allAssets.where((a) => a.name == groupName).toList(),
      loading: () => assets, // Show initial assets while loading
      error: (_, __) => [], // Show empty list on error
    );

    if (currentGroupAssets.isEmpty && !assetsState.isLoading) {
      // If all assets in the group were deleted, pop the screen
      // Use a post-frame callback to avoid build-time navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
      ),
      body: ListView.builder(
        itemCount: currentGroupAssets.length,
        itemBuilder: (context, index) {
          final asset = currentGroupAssets[index];
          return Slidable(
            key: ValueKey(asset.id), // Unique key for each slidable
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Asset'),
                        content: const Text('Are you sure you want to delete this specific asset?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ) ?? false;

                    if (confirm && context.mounted) {
                      try {
                        await ref.read(assetsProvider.notifier).deleteAsset(asset.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Asset deleted successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete asset: $e')),
                        );
                      }
                    }
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
                title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Purchased on ${DateFormat.yMMMd().format(asset.purchaseDate)}'),
                trailing: Text(
                  NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ', decimalDigits: 0).format(asset.purchasePrice),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssetDetailsScreen(asset: asset),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
