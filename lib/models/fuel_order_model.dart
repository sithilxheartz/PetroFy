import 'package:cloud_firestore/cloud_firestore.dart';

class FuelOrderModel {
  final String? id;
  final DateTime orderDate;
  final String fuelType;
  final double quantity; // Must be between 5000 and 7000
  final String confirmedAdminId;
  final String confirmedAdminName;
  final String receiptNumber;
  final String bowserNumber; // Format: LL-1234
  final String status; // 'pending', 'dispatched', 'delivered'

  FuelOrderModel({
    this.id,
    required this.orderDate,
    required this.fuelType,
    required this.quantity,
    required this.confirmedAdminId,
    required this.confirmedAdminName,
    required this.receiptNumber,
    required this.bowserNumber,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'orderDate': Timestamp.fromDate(orderDate),
      'fuelType': fuelType,
      'quantity': quantity,
      'confirmedAdminId': confirmedAdminId,
      'confirmedAdminName': confirmedAdminName,
      'receiptNumber': receiptNumber,
      'bowserNumber': bowserNumber,
      'status': status,
    };
  }

  factory FuelOrderModel.fromMap(Map<String, dynamic> map, String docId) {
    return FuelOrderModel(
      id: docId,
      orderDate: (map['orderDate'] as Timestamp).toDate(),
      fuelType: map['fuelType'] ?? '',
      quantity: (map['quantity'] as num).toDouble(),
      confirmedAdminId: map['confirmedAdminId'] ?? '',
      confirmedAdminName: map['confirmedAdminName'] ?? '',
      receiptNumber: map['receiptNumber'] ?? '',
      bowserNumber: map['bowserNumber'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }
}