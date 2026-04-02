import 'package:cloud_firestore/cloud_firestore.dart';

class FuelSaleModel {
  final String? id;
  final String fuelType;
  final DateTime dateTime;
  final String pumperName;
  final String pumperId;
  final double soldQuantity;
  final String tankId;
  final double soldTotalPrice;
  // NEW FIELDS
  final String status; // 'pending', 'payment received', 'added to safe'
  final String? paymentReceiverId;
  final String? paymentReceiverName;

  FuelSaleModel({
    this.id,
    required this.fuelType,
    required this.dateTime,
    required this.pumperName,
    required this.pumperId,
    required this.soldQuantity,
    required this.tankId,
    required this.soldTotalPrice,
    this.status = 'pending', // Default to pending
    this.paymentReceiverId,
    this.paymentReceiverName,
  });

  factory FuelSaleModel.fromMap(Map<String, dynamic> map, String docId) {
    return FuelSaleModel(
      id: docId,
      fuelType: map['fuelType'] ?? 'Unknown',
      dateTime: map['dateTime'] != null 
          ? (map['dateTime'] as Timestamp).toDate() 
          : DateTime.now(),
      pumperName: map['pumperName'] ?? '',
      pumperId: map['pumperId'] ?? '',
      soldQuantity: (map['soldQuantity'] as num).toDouble(),
      tankId: map['tankId'] ?? '',
      soldTotalPrice: (map['soldTotalPrice'] as num).toDouble(),
      // Mapping new fields
      status: map['status'] ?? 'pending',
      paymentReceiverId: map['paymentReceiverId'],
      paymentReceiverName: map['paymentReceiverName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fuelType': fuelType,
      'dateTime': dateTime,
      'pumperName': pumperName,
      'pumperId': pumperId,
      'soldQuantity': soldQuantity,
      'tankId': tankId,
      'soldTotalPrice': soldTotalPrice,
      // Adding new fields to map
      'status': status,
      'paymentReceiverId': paymentReceiverId,
      'paymentReceiverName': paymentReceiverName,
    };
  }
}