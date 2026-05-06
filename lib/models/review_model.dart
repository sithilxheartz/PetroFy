import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String fullName; // Consistent naming
  final String comment;
  final double rating;
  final DateTime timestamp;

  ReviewModel({
    required this.id,
    required this.fullName,
    required this.comment,
    required this.rating,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'comment': comment,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReviewModel(
      id: docId,
      fullName: map['fullName'] ?? 'Anonymous User',
      comment: map['comment'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}