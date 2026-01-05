import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Zonova_Mist/src/features/home/assets/models/asset_model.dart';
import 'package:Zonova_Mist/src/shared/widgets/common_image_manager.dart';
import 'package:Zonova_Mist/src/features/home/assets/edit_asset_screen.dart';

class AssetDetailsScreen extends StatelessWidget {
  final AssetModel asset;

  const AssetDetailsScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(asset.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditAssetScreen(asset: asset),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Management Section
            _buildPhotoSection(context),
            const SizedBox(height: 24),

            // Asset Details
            _buildDetailSection(context, 'Asset Details', [
              _buildDetailRow('Category', asset.category),
              _buildDetailRow('Brand', asset.brand ?? 'N/A'),
              _buildDetailRow('Quantity', asset.quantity.toString()),
            ]),
            const SizedBox(height: 24),

            // Purchase Information
            _buildDetailSection(context, 'Purchase Information', [
              _buildDetailRow('Purchase Price', NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ').format(asset.purchasePrice)),
              _buildDetailRow('Purchase Date', DateFormat.yMMMd().format(asset.purchaseDate)),
            ]),
            const SizedBox(height: 24),

            // Warranty Information
            if (asset.warrantyEndDate != null)
              _buildWarrantySection(context),

            // Description
            if (asset.description != null && asset.description!.isNotEmpty)
              _buildDescriptionSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        CommonImageManager(
          entityType: 'asset',
          entityId: asset.id,
        ),
      ],
    );
  }

  Widget _buildWarrantySection(BuildContext context) {
    final now = DateTime.now();
    final isExpired = asset.warrantyEndDate!.isBefore(now);
    final expiresIn = asset.warrantyEndDate!.difference(now);
    final days = expiresIn.inDays;

    final statusText = isExpired ? 'Expired' : 'Active';
    final statusColor = isExpired ? Colors.red : Colors.green;
    final subText = isExpired
        ? 'Warranty ended on ${DateFormat.yMMMd().format(asset.warrantyEndDate!)}'
        : 'Expires in $days ${days == 1 ? 'day' : 'days'}';

    return Column(
      children: [
        _buildDetailSection(context, 'Warranty Information', [
          _buildDetailRow('Status', statusText, valueColor: statusColor),
          _buildDetailRow('Expires On', DateFormat.yMMMd().format(asset.warrantyEndDate!), subValue: subText),
          if (asset.warrantyDetails != null && asset.warrantyDetails!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(asset.warrantyDetails!, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
            ),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildDescriptionSection(BuildContext context) {
    return _buildDetailSection(context, 'Description', [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(asset.description!, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
        ),
      ]);
  }

  Widget _buildDetailSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, String? subValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
                if (subValue != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      subValue,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
