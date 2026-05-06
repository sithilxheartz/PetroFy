import 'package:cloud_firestore/cloud_firestore.dart';

class FuelTankModel {
  final String id;
  final String fuelType;
  final double capacity;
  final double currentQuantity;
  final double fuelPrice;
  final DateTime lastRefillDate;

  FuelTankModel({
    required this.id,
    required this.fuelType,
    required this.capacity,
    required this.currentQuantity,
    required this.fuelPrice,
    required this.lastRefillDate,
  });

  // --- FIXED: ADDED FOR DROPDOWN STABILITY ---
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelTankModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
  // ------------------------------------------

  factory FuelTankModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FuelTankModel(
      id: documentId,
      fuelType: map['fuelType'] ?? '',
      capacity: (map['capacity'] ?? 0).toDouble(),
      currentQuantity: (map['currentQuantity'] ?? 0).toDouble(),
      fuelPrice: (map['fuelPrice'] ?? 0).toDouble(),
      lastRefillDate: (map['lastRefillDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fuelType': fuelType,
      'capacity': capacity,
      'currentQuantity': currentQuantity,
      'fuelPrice': fuelPrice,
      'lastRefillDate': lastRefillDate,
    };
  }
}