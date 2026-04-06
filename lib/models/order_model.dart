import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double totalAmount;
  final String status; // 'Pending', 'Paid', 'Delivered'
  final DateTime timestamp;
  final String deliveryAddress;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.timestamp,
    required this.deliveryAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'timestamp': timestamp,
      'deliveryAddress': deliveryAddress,
    };
  }
}