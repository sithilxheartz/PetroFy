import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fuel_sale_model.dart';

class SalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _salesCollection = FirebaseFirestore.instance.collection('fuelSales');
  final CollectionReference _tanksCollection = FirebaseFirestore.instance.collection('fuelTanks');

  Future<String?> recordSale(FuelSaleModel sale) async {
    try {
      DocumentReference tankRef = _tanksCollection.doc(sale.tankId);

      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot tankSnap = await transaction.get(tankRef);

        if (!tankSnap.exists) return "Error: Tank configuration not found.";

        double currentStock = (tankSnap['currentQuantity'] as num).toDouble();

        if (currentStock < sale.soldQuantity) {
          return "Insufficient fuel! Remaining: ${currentStock.toStringAsFixed(2)}L";
        }

        transaction.update(tankRef, {
          'currentQuantity': currentStock - sale.soldQuantity,
        });

        transaction.set(_salesCollection.doc(), sale.toMap());

        return null; // Success
      });
    } catch (e) {
      return e.toString();
    }
  }

  // FIXED: Corrected .where syntax for pumperId
  Stream<List<FuelSaleModel>> getPumperSales(String pumperId) {
    return _firestore
        .collection('fuelSales')
        .where('pumperId', isEqualTo: pumperId) 
        .orderBy('dateTime', descending: true) 
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FuelSaleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

Stream<List<FuelSaleModel>> getPumperFilteredSales(String pumperId, DateTime startDate) {
  return _firestore
      .collection('fuelSales')
      .where('pumperId', isEqualTo: pumperId)
      .where('dateTime', isGreaterThanOrEqualTo: startDate)
      .orderBy('dateTime', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => FuelSaleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList());
}
}