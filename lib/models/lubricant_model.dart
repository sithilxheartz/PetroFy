class LubricantModel {
  final String? id;
  final String name;
  final String description;
  final String brand;
  final String category;
  final double buyingPrice;
  final double sellingPrice;
  final String imageUrl;
  final String size; // Changed from List<String> to String
  final int stockQuantity;

  LubricantModel({
    this.id,
    required this.name,
    required this.description,
    required this.brand,
    required this.category,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.imageUrl,
    required this.size,
    required this.stockQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'brand': brand,
      'category': category,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'imageUrl': imageUrl,
      'size': size, // Saves as a simple String record
      'stockQuantity': stockQuantity,
    };
  }

  factory LubricantModel.fromMap(Map<String, dynamic> map, String docId) {
    return LubricantModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      brand: map['brand'] ?? '',
      category: map['category'] ?? 'General',
      buyingPrice: (map['buyingPrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      size: map['size'] ?? 'N/A', // Reads as a simple String
      stockQuantity: map['stockQuantity'] ?? 0,
    );
  }
}
