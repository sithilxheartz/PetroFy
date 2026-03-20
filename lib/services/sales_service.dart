import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fuel_sale_model.dart';

class SalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _salesCollection = FirebaseFirestore.instance.collection('fuelSales');
  final CollectionReference _tanksCollection = FirebaseFirestore.instance.collection('fuelTanks');

  // 1. Record a New Sale (with Atomic Transaction)
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

        // A. Deduct from Tank
        transaction.update(tankRef, {
          'currentQuantity': currentStock - sale.soldQuantity,
        });

        // B. Create Sales Record
        transaction.set(_salesCollection.doc(), sale.toMap());

        return null; // Success
      });
    } catch (e) {
      return e.toString();
    }
  }

  // 2. Stream Sales History (Real-time)
  Stream<List<FuelSaleModel>> getSalesHistory() {
    return _salesCollection
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FuelSaleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 3. Get Total Revenue (Optional Helper)
  Future<double> getTotalRevenue() async {
    QuerySnapshot query = await _salesCollection.get();
    double total = 0;
    for (var doc in query.docs) {
      total += (doc['soldTotalPrice'] as num).toDouble();
    }
    return total;
  }
}