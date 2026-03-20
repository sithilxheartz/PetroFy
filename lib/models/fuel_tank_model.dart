import 'package:cloud_firestore/cloud_firestore.dart';

class FuelTankModel {
  final String id;
  final String fuelType; // e.g., Octane 92, Super Diesel
  final double capacity;
  final double currentQuantity;
  final DateTime lastRefillDate;

  FuelTankModel({
    required this.id,
    required this.fuelType,
    required this.capacity,
    required this.currentQuantity,
    required this.lastRefillDate,
  });

  // Percentage for UI progress bars
  double get fillPercentage => (currentQuantity / capacity);

  factory FuelTankModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FuelTankModel(
      id: documentId,
      fuelType: map['fuelType'] ?? '',
      capacity: (map['capacity'] ?? 0).toDouble(),
      currentQuantity: (map['currentQuantity'] ?? 0).toDouble(),
      lastRefillDate: (map['lastRefillDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fuelType': fuelType,
      'capacity': capacity,
      'currentQuantity': currentQuantity,
      'lastRefillDate': lastRefillDate,
    };
  }
}