import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/fuel_sale_model.dart';

class SalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _salesCollection = FirebaseFirestore.instance.collection('fuelSales');
  final CollectionReference _tanksCollection = FirebaseFirestore.instance.collection('fuelTanks');
  final CollectionReference _historyCollection = FirebaseFirestore.instance.collection('fuelSaleHistory');

  Future<String?> recordSale(FuelSaleModel sale) async {
    try {
      DocumentReference tankRef = _tanksCollection.doc(sale.tankId);
      String todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
      DocumentReference historyRef = _historyCollection.doc(todayId);

      return await _firestore.runTransaction((transaction) async {
        // 1. Check Tank Stock
        DocumentSnapshot tankSnap = await transaction.get(tankRef);
        if (!tankSnap.exists) return "Error: Tank not found.";

        double currentStock = (tankSnap['currentQuantity'] as num).toDouble();
        if (currentStock < sale.soldQuantity) {
          return "Insufficient fuel! Remaining: ${currentStock.toStringAsFixed(2)}L";
        }

        // 2. Update Tank Stock
        transaction.update(tankRef, {
          'currentQuantity': currentStock - sale.soldQuantity,
        });

        // 3. Update Daily Aggregated History
        String fieldName = _getHistoryFieldName(sale.fuelType);
        transaction.set(historyRef, {
          'date': Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)),
          fieldName: FieldValue.increment(sale.soldQuantity),
        }, SetOptions(merge: true));

        // 4. Save Individual Transaction with NEW STATUS fields
        // Note: We use sale.toMap() which now includes the 'pending' status
        transaction.set(_salesCollection.doc(), sale.toMap());

        return null; // Success
      });
    } catch (e) {
      return e.toString();
    }
  }

  // --- ADMIN APPROVAL LOGIC ---
  
  /// Call this when an Admin receives cash from a pumper
  Future<void> approvePayment(String saleId, String adminId, String adminName) async {
    await _salesCollection.doc(saleId).update({
      'status': 'payment received',
      'paymentReceiverId': adminId,
      'paymentReceiverName': adminName,
    });
  }

  /// Call this when the manager puts the money in the physical safe
  Future<void> moveToSafe(String saleId) async {
    await _salesCollection.doc(saleId).update({
      'status': 'added to safe',
    });
  }

  /// Updates the status and records which Admin performed the action
  Future<void> updatePaymentStatus({
    required String saleId, 
    required String newStatus, 
    required String adminId, 
    required String adminName
  }) async {
    try {
      await _firestore.collection('fuelSales').doc(saleId).update({
        'status': newStatus,
        'paymentReceiverId': adminId,
        'paymentReceiverName': adminName,
        'approvalTime': FieldValue.serverTimestamp(), // Optional: adds a timestamp of approval
      });
    } catch (e) {
      throw Exception("Failed to update status: $e");
    }
  }

  // Helper mapping
  String _getHistoryFieldName(String fuelType) {
    switch (fuelType) {
      case 'Auto Diesel': return 'dieselSale';
      case 'Super Diesel': return 'superDieselSale';
      case 'Petrol 92 Octane': return '92PetrolSale';
      case 'Petrol 95 Octane': return '95PetrolSale';
      default: return 'otherSale';
    }
  }

  // --- QUERY METHODS ---

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
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('dateTime', descending: true) 
        .snapshots()
        .map((snapshot) => snapshot.docs
              .map((doc) => FuelSaleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList());
  }
}