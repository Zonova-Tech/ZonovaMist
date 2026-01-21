import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Import the collection package

import 'package:Zonova_Mist/src/features/home/assets/providers/asset_provider.dart';
import 'package:Zonova_Mist/src/features/home/assets/models/asset_model.dart';
import 'package:Zonova_Mist/src/features/home/assets/asset_details_screen.dart';
import 'package:Zonova_Mist/src/features/home/assets/add_asset_screen.dart';
import 'package:Zonova_Mist/src/features/home/assets/asset_group_screen.dart';

class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsyncValue = ref.watch(assetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAssetScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: assetsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Failed to load assets.\nPlease try again later.\n\nError: $error',
            textAlign: TextAlign.center,
          ),
        ),
        data: (assets) {
          // Calculate the total value and total quantity of all assets
          final totalValue = assets.fold<double>(0, (sum, item) => sum + (item.purchasePrice * item.quantity));
          final totalQuantity = assets.fold<int>(0, (sum, item) => sum + item.quantity);

          // Group assets by name
          final groupedAssets = groupBy(assets, (AssetModel asset) => asset.name);

          return RefreshIndicator(
            onRefresh: () => ref.read(assetsProvider.notifier).loadAssets(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _buildStatCard(
                      title: 'Total Quantity', // <-- Changed from Total Assets
                      value: totalQuantity.toString(),
                      icon: Icons.business_center,
                      color: Colors.blue.shade700,
                    ),
                    _buildStatCard(
                      title: 'Total Value',
                      value: NumberFormat.currency(locale: 'en_LK', symbol: 'Rs.').format(totalValue),
                      icon: Icons.account_balance_wallet,
                      color: Colors.green.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Asset Groups', // <-- Changed from All Assets
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (assets.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No assets found. Tap the + icon to add one.'),
                    ),
                  )
                else
                  _buildGroupedAssetList(context, groupedAssets),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                maxLines: 1,
              ),
            ),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // Updated to sum quantities for the trailing text
  Widget _buildGroupedAssetList(BuildContext context, Map<String, List<AssetModel>> groupedAssets) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedAssets.length,
      itemBuilder: (context, index) {
        final groupName = groupedAssets.keys.elementAt(index);
        final groupAssets = groupedAssets[groupName]!;
        // Calculate the total quantity for the group
        final totalQuantityInGroup = groupAssets.fold<int>(0, (sum, asset) => sum + asset.quantity);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
            title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(groupAssets.first.category),
            trailing: Text(
              'x$totalQuantityInGroup', // <-- The fix is here
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            onTap: () {
              // If there's only one entry AND its quantity is 1, go to details
              if (groupAssets.length == 1 && groupAssets.first.quantity == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssetDetailsScreen(asset: groupAssets.first),
                  ),
                );
              } else {
                // Otherwise, go to the group screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssetGroupScreen(
                      groupName: groupName,
                      assets: groupAssets,
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
