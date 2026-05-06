import 'package:cloud_firestore/cloud_firestore.dart';

class ReorderSuggestionModel {
  final String id;
  final String fuelType;
  final double currentQuantity;
  final double currentPercent;
  final double dailyAvgConsumption;
  final double daysUntilThreshold;
  final DateTime predictedDate;
  final int suggestedOrderQty;
  final double capacity;
  final double thresholdQty;
  final DateTime createdAt;
  final String status; // pending / ordered / dismissed

  ReorderSuggestionModel({
    required this.id,
    required this.fuelType,
    required this.currentQuantity,
    required this.currentPercent,
    required this.dailyAvgConsumption,
    required this.daysUntilThreshold,
    required this.predictedDate,
    required this.suggestedOrderQty,
    required this.capacity,
    required this.thresholdQty,
    required this.createdAt,
    required this.status,
  });

  factory ReorderSuggestionModel.fromMap(
      Map<String, dynamic> map, String docId) {
    return ReorderSuggestionModel(
      id:                   docId,
      fuelType:             map['fuelType']             ?? '',
      currentQuantity:      (map['currentQuantity']     ?? 0).toDouble(),
      currentPercent:       (map['currentPercent']      ?? 0).toDouble(),
      dailyAvgConsumption:  (map['dailyAvgConsumption'] ?? 0).toDouble(),
      daysUntilThreshold:   (map['daysUntilThreshold']  ?? 0).toDouble(),
      predictedDate:        (map['predictedDate'] as Timestamp).toDate(),
      suggestedOrderQty:    (map['suggestedOrderQty']   ?? 0).toInt(),
      capacity:             (map['capacity']            ?? 0).toDouble(),
      thresholdQty:         (map['thresholdQty']        ?? 0).toDouble(),
      createdAt:            (map['createdAt'] as Timestamp).toDate(),
      status:               map['status']               ?? 'pending',
    );
  }
}