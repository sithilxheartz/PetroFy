import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add review to the lubricant's subcollection
  Future<void> addReview(String productId, ReviewModel review) async {
    await _db
        .collection('lubricants')
        .doc(productId)
        .collection('reviews')
        .add(review.toMap());
  }

  // Stream reviews for a specific product
  Stream<List<ReviewModel>> getReviews(String productId) {
    return _db
        .collection('lubricants')
        .doc(productId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}