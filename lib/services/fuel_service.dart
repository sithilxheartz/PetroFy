import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fuel_tank_model.dart';

class FuelService {
  final CollectionReference _tankCollection = 
      FirebaseFirestore.instance.collection('fuelTanks');

  // 1. Add New Tank
  Future<void> addFuelTank(FuelTankModel tank) async {
    await _tankCollection.add(tank.toMap());
  }

  // 2. Stream of all tanks (for real-time dashboard)
  Stream<List<FuelTankModel>> getFuelTanks() {
    return _tankCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FuelTankModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 3. Update Quantity (When fuel is sold)
  Future<void> updateQuantity(String id, double newQuantity) async {
    await _tankCollection.doc(id).update({'currentQuantity': newQuantity});
  }

  // Add this to your FuelService class
Stream<List<FuelTankModel>> getTanksByType(String? type) {
  if (type == null || type == 'All') {
    return getFuelTanks(); // Returns all 4 tanks
  }
  return _tankCollection
      .where('fuelType', isEqualTo: type)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return FuelTankModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  });
}
}