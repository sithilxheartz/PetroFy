import 'package:cloud_firestore/cloud_firestore.dart';

class SwapRequestModel {
  final String? id;
  final String requesterId;       // Pumper A (who wants to swap)
  final String requesterName;
  final String targetId;          // Pumper B (who they want to swap with)
  final String targetName;
  final String requesterShiftId;  // Pumper A's shift document ID
  final String targetShiftId;     // Pumper B's shift document ID
  final String requesterShiftType;   // "Day Shift" / "Night Shift"
  final String targetShiftType;
  final String requesterPump;
  final String targetPump;
  final DateTime swapDate;
  final String status; // "pending" / "accepted" / "rejected"
  final DateTime createdAt;

  SwapRequestModel({
    this.id,
    required this.requesterId,
    required this.requesterName,
    required this.targetId,
    required this.targetName,
    required this.requesterShiftId,
    required this.targetShiftId,
    required this.requesterShiftType,
    required this.targetShiftType,
    required this.requesterPump,
    required this.targetPump,
    required this.swapDate,
    required this.status,
    required this.createdAt,
  });

  factory SwapRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return SwapRequestModel(
      id: docId,
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      targetId: map['targetId'] ?? '',
      targetName: map['targetName'] ?? '',
      requesterShiftId: map['requesterShiftId'] ?? '',
      targetShiftId: map['targetShiftId'] ?? '',
      requesterShiftType: map['requesterShiftType'] ?? '',
      targetShiftType: map['targetShiftType'] ?? '',
      requesterPump: map['requesterPump'] ?? '',
      targetPump: map['targetPump'] ?? '',
      swapDate: (map['swapDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'targetId': targetId,
      'targetName': targetName,
      'requesterShiftId': requesterShiftId,
      'targetShiftId': targetShiftId,
      'requesterShiftType': requesterShiftType,
      'targetShiftType': targetShiftType,
      'requesterPump': requesterPump,
      'targetPump': targetPump,
      'swapDate': Timestamp.fromDate(swapDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}