class CartItemModel {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final String size;
  int quantity;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.size,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'size': size,
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] as num).toDouble(),
      size: map['size'] ?? '',
      quantity: map['quantity'] ?? 1,
    );
  }
}