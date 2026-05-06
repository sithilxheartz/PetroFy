import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item_model.dart';

class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Dynamically points to the current logged-in user's cart
  CollectionReference get _userCart {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return _db.collection('users').doc(user.uid).collection('cart');
  }

  // Add item: If it exists, increment quantity. If not, create it.
  Future<void> addToCart(CartItemModel item) async {
    final doc = await _userCart.doc(item.productId).get();
    
    if (doc.exists) {
      await _userCart.doc(item.productId).update({
        'quantity': FieldValue.increment(1),
      });
    } else {
      await _userCart.doc(item.productId).set(item.toMap());
    }
  }

  // Stream for real-time cart updates (Badges and Cart Page)
  Stream<List<CartItemModel>> getCartStream() {
    return _userCart.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => CartItemModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> removeItem(String productId) async {
    await _userCart.doc(productId).delete();
  }

  Future<void> clearAll() async {
    final snapshots = await _userCart.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }
}