import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Zonova_Mist/src/features/home/assets/models/asset_model.dart';
import 'package:Zonova_Mist/src/features/home/assets/asset_details_screen.dart';

class AssetGroupScreen extends StatelessWidget {
  final String groupName;
  final List<AssetModel> assets;

  const AssetGroupScreen({
    super.key,
    required this.groupName,
    required this.assets,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
      ),
      body: ListView.builder(
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final asset = assets[index];
          return Card(
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
          );
        },
      ),
    );
  }
}
