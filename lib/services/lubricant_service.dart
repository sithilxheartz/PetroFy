import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lubricant_model.dart';

class LubricantService {
  final CollectionReference _db = FirebaseFirestore.instance.collection('lubricants');

  Future<void> addProduct(LubricantModel product) async {
    await _db.add(product.toMap());
  }

  Stream<List<LubricantModel>> getProducts() {
    return _db.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => LubricantModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }
}