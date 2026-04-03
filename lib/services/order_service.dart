import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fuel_order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrderAndUpdateStock(FuelOrderModel order) async {
    // We need to find the correct tank to update based on the fuel type
    QuerySnapshot tankQuery = await _firestore
        .collection('fuelTanks')
        .where('fuelType', isEqualTo: order.fuelType)
        .limit(1)
        .get();

    if (tankQuery.docs.isEmpty) {
      throw Exception("No tank found for ${order.fuelType}");
    }

    DocumentReference tankRef = tankQuery.docs.first.reference;

    return await _firestore.runTransaction((transaction) async {
      // 1. Get current tank data
      DocumentSnapshot tankSnap = await transaction.get(tankRef);
      double currentQty = (tankSnap['currentQuantity'] as num).toDouble();
      double capacity = (tankSnap['capacity'] as num).toDouble();

      // Optional: Check for overflow
      if (currentQty + order.quantity > capacity) {
        throw Exception("Tank overflow! Only ${capacity - currentQty}L space left.");
      }

      // 2. Create the Order Record
      DocumentReference orderRef = _firestore.collection('fuelOrders').doc();
      transaction.set(orderRef, order.toMap());

      // 3. Update the Tank Quantity
      transaction.update(tankRef, {
        'currentQuantity': currentQty + order.quantity,
      });
    });
  }
}