import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:Zonova_Mist/src/features/home/assets/models/asset_model.dart';
import 'package:Zonova_Mist/src/features/home/assets/providers/asset_provider.dart';

class EditAssetScreen extends ConsumerStatefulWidget {
  final AssetModel asset;

  const EditAssetScreen({super.key, required this.asset});

  @override
  ConsumerState<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends ConsumerState<EditAssetScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isSaving = true);

      final formData = _formKey.currentState!.value;
      final updatedAsset = AssetModel(
        id: widget.asset.id,
        name: formData['name'],
        category: formData['category'],
        brand: formData['brand'],
        quantity: int.parse(formData['quantity']),
        purchasePrice: double.parse(formData['purchasePrice']),
        purchaseDate: formData['purchaseDate'],
        description: formData['description'],
        warrantyEndDate: formData['warrantyEndDate'],
        warrantyDetails: formData['warrantyDetails'],
        photos: widget.asset.photos, // Photos are managed separately
      );

      try {
        await ref.read(assetsProvider.notifier).updateAsset(updatedAsset);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asset updated successfully!')),
          );
          // Pop back two screens to the AssetsScreen
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 2);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update asset: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteAsset() async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: const Text('Are you sure you want to permanently delete this asset and all its photos?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await ref.read(assetsProvider.notifier).deleteAsset(widget.asset.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset deleted successfully')),
        );
        // Pop back two screens to the AssetsScreen
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete asset: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create a map with string values for the form fields
    final initialFormValues = {
      'name': widget.asset.name,
      'category': widget.asset.category,
      'purchasePrice': widget.asset.purchasePrice.toString(),
      'purchaseDate': widget.asset.purchaseDate,
      'description': widget.asset.description,
      'quantity': widget.asset.quantity.toString(),
      'brand': widget.asset.brand,
      'warrantyEndDate': widget.asset.warrantyEndDate,
      'warrantyDetails': widget.asset.warrantyDetails,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Asset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteAsset,
            tooltip: 'Delete Asset',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialFormValues, // <-- The fix is here
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormBuilderTextField(name: 'name', decoration: const InputDecoration(labelText: 'Asset Name'), validator: FormBuilderValidators.required()),
              const SizedBox(height: 16),
              FormBuilderDropdown(name: 'category', decoration: const InputDecoration(labelText: 'Category'), items: ['Furniture', 'Electronics', 'Appliances', 'Linens', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), validator: FormBuilderValidators.required()),
              const SizedBox(height: 16),
              FormBuilderTextField(name: 'brand', decoration: const InputDecoration(labelText: 'Brand (Optional)')),
              const SizedBox(height: 16),
              FormBuilderTextField(name: 'quantity', decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number, validator: FormBuilderValidators.compose([FormBuilderValidators.required(), FormBuilderValidators.integer()])),
              const SizedBox(height: 16),
              FormBuilderTextField(name: 'purchasePrice', decoration: const InputDecoration(labelText: 'Purchase Price', prefixText: 'Rs. '), keyboardType: TextInputType.number, validator: FormBuilderValidators.compose([FormBuilderValidators.required(), FormBuilderValidators.numeric()])),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(name: 'purchaseDate', decoration: const InputDecoration(labelText: 'Purchase Date'), inputType: InputType.date, format: DateFormat('yyyy-MM-dd'), validator: FormBuilderValidators.required()),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(name: 'warrantyEndDate', decoration: const InputDecoration(labelText: 'Warranty End Date (Optional)'), inputType: InputType.date, format: DateFormat('yyyy-MM-dd')),
              const SizedBox(height: 16),
              FormBuilderTextField(name: 'description', decoration: const InputDecoration(labelText: 'Description (Optional)'), maxLines: 3),
              const SizedBox(height: 16),
              FormBuilderTextField(name: 'warrantyDetails', decoration: const InputDecoration(labelText: 'Warranty Details (Optional)'), maxLines: 2),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _submitForm,
                child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,)) : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
