import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftModel {
  final String? id;
  final String pumperId;
  final String pumperName;
  final DateTime date;
  final String shiftType;
  final String pumpNumber;
  final String status;
  final bool isAutoAssigned; // ← ADD THIS

  ShiftModel({
    this.id,
    required this.pumperId,
    required this.pumperName,
    required this.date,
    required this.shiftType,
    required this.pumpNumber,
    this.status = 'pending',
    this.isAutoAssigned = false, // ← ADD THIS
  });

  factory ShiftModel.fromMap(Map<String, dynamic> map, String docId) {
    return ShiftModel(
      id: docId,
      pumperId: map['pumperId'] ?? '',
      pumperName: map['pumperName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      shiftType: map['shiftType'] ?? '',
      pumpNumber: map['pumpNumber'] ?? '',
      status: map['status'] ?? 'pending',
      isAutoAssigned: map['isAutoAssigned'] ?? false, // ← ADD THIS
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pumperId': pumperId,
      'pumperName': pumperName,
      'date': date,
      'shiftType': shiftType,
      'pumpNumber': pumpNumber,
      'status': status,
      'isAutoAssigned': isAutoAssigned, // ← ADD THIS
    };
  }
}