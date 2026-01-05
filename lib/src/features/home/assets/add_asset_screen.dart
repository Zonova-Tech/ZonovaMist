import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:Zonova_Mist/src/features/home/assets/models/asset_model.dart';
import 'package:Zonova_Mist/src/features/home/assets/providers/asset_provider.dart';

class AddAssetScreen extends ConsumerStatefulWidget {
  const AddAssetScreen({super.key});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      final formData = _formKey.currentState!.value;

      final newAsset = AssetModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary unique ID
        name: formData['name'],
        category: formData['category'],
        purchasePrice: double.parse(formData['purchasePrice']),
        purchaseDate: formData['purchaseDate'],
        brand: formData['brand'],
        quantity: int.parse(formData['quantity']),
        description: formData['description'],
      );

      try {
        await ref.read(assetsProvider.notifier).addAsset(newAsset);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asset added successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add asset: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Asset'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormBuilderTextField(
                name: 'name',
                decoration: const InputDecoration(labelText: 'Asset Name'),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown(
                name: 'category',
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Furniture', 'Electronics', 'Appliances', 'Linens', 'Other']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'brand',
                decoration: const InputDecoration(labelText: 'Brand (Optional)'),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'quantity',
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.integer(),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'purchasePrice',
                decoration: const InputDecoration(labelText: 'Purchase Price', prefixText: 'Rs. '),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'purchaseDate',
                decoration: const InputDecoration(labelText: 'Purchase Date'),
                inputType: InputType.date,
                format: DateFormat('yyyy-MM-dd'),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'description',
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _submitForm,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
                    : const Text('Save Asset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
