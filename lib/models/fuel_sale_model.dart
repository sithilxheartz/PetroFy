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

  FuelSaleModel({
    this.id,
    required this.fuelType,
    required this.dateTime,
    required this.pumperName,
    required this.pumperId,
    required this.soldQuantity,
    required this.tankId,
    required this.soldTotalPrice,
  });

factory FuelSaleModel.fromMap(Map<String, dynamic> map, String docId) {
  return FuelSaleModel(
    id: docId,
    fuelType: map['fuelType'] ?? 'Unknown',
    // Safety check for Timestamp conversion
    dateTime: map['dateTime'] != null 
        ? (map['dateTime'] as Timestamp).toDate() 
        : DateTime.now(),
    pumperName: map['pumperName'] ?? '',
    pumperId: map['pumperId'] ?? '',
    // Use .toDouble() to prevent "int is not a subtype of double" errors
    soldQuantity: (map['soldQuantity'] as num).toDouble(),
    tankId: map['tankId'] ?? '',
    soldTotalPrice: (map['soldTotalPrice'] as num).toDouble(),
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
    };
  }
}