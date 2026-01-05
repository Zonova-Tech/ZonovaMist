// lib/src/features/home/assets/models/asset_model.dart

class AssetModel {
  final String id;
  final String name;
  final String category;
  final double purchasePrice;
  final DateTime purchaseDate;
  final String? description;
  final int quantity;
  final String? brand;
  final List<String> photos;
  final DateTime? warrantyEndDate;
  final String? warrantyDetails;

  AssetModel({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.purchaseDate,
    this.description,
    this.quantity = 1,
    this.brand,
    this.photos = const [],
    this.warrantyEndDate,
    this.warrantyDetails,
  });

  // Correctly parses the ID from the server response (_id)
  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['_id'] as String, // <-- The fix is here
      name: json['name'] as String,
      category: json['category'] as String,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      description: json['description'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      brand: json['brand'] as String?,
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      warrantyEndDate: json['warrantyEndDate'] != null ? DateTime.parse(json['warrantyEndDate'] as String) : null,
      warrantyDetails: json['warrantyDetails'] as String?,
    );
  }

  // For sending data to the API (expects numbers)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'description': description,
      'quantity': quantity,
      'brand': brand,
      'photos': photos,
      'warrantyEndDate': warrantyEndDate?.toIso8601String(),
      'warrantyDetails': warrantyDetails,
    };
  }

  // For populating a form (expects strings)
  Map<String, dynamic> toFormValues() {
    return {
      'name': name,
      'category': category,
      'purchasePrice': purchasePrice.toString(),
      'purchaseDate': purchaseDate,
      'description': description,
      'quantity': quantity.toString(),
      'brand': brand,
      'warrantyEndDate': warrantyEndDate,
      'warrantyDetails': warrantyDetails,
    };
  }
}
