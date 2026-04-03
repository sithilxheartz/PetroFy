class LubricantModel {
  final String? id;
  final String name;
  final String description;
  final String brand;
  final double buyingPrice;
  final double sellingPrice;
  final String imageUrl;
  final List<String> sizes; // e.g., ["1L", "4L", "5L"]
  final int stockQuantity;

  LubricantModel({
    this.id,
    required this.name,
    required this.description,
    required this.brand,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.imageUrl,
    required this.sizes,
    required this.stockQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'brand': brand,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'imageUrl': imageUrl,
      'sizes': sizes,
      'stockQuantity': stockQuantity,
    };
  }

  factory LubricantModel.fromMap(Map<String, dynamic> map, String docId) {
    return LubricantModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      brand: map['brand'] ?? '',
      buyingPrice: (map['buyingPrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      sizes: List<String>.from(map['sizes'] ?? []),
      stockQuantity: map['stockQuantity'] ?? 0,
    );
  }
}