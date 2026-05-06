import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/lubricant_model.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _service = CartService();

  // Add to Firestore Cart
  Future<void> addProduct(LubricantModel product) async {
    final item = CartItemModel(
      productId: product.id!,
      name: product.name,
      imageUrl: product.imageUrl,
      price: product.sellingPrice,
      size: product.size,
    );
    await _service.addToCart(item);
    notifyListeners();
  }

  // Getter for the Stream
  Stream<List<CartItemModel>> get cartItemsStream => _service.getCartStream();

  Future<void> deleteItem(String id) async => await _service.removeItem(id);
}