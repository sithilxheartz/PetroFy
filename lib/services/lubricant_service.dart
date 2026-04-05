import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lubricant_model.dart';

class LubricantService {
  final CollectionReference _db = FirebaseFirestore.instance.collection('lubricants');

  Future<void> addProduct(LubricantModel product) async {
    await _db.add(product.toMap());
  }
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
  await _db.doc(id).update(data);
}

Future<void> updateStockQuantity(String productId, int addedQty) async {
  await _db.doc(productId).update({
    'stockQuantity': FieldValue.increment(addedQty),
  });
}

Future<void> deleteProduct(String id) async {
  await _db.doc(id).delete();
}

  Stream<List<LubricantModel>> getProducts() {
    return _db.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => LubricantModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }
}