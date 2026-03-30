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
      // 1. Define Document References
      DocumentReference tankRef = _tanksCollection.doc(sale.tankId);
      
      // Use the date (yyyy-MM-dd) as the ID so there is only ONE doc per day
      String todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
      DocumentReference historyRef = _historyCollection.doc(todayId);

      return await _firestore.runTransaction((transaction) async {
        // 2. Get Current Tank Data
        DocumentSnapshot tankSnap = await transaction.get(tankRef);
        if (!tankSnap.exists) return "Error: Tank not found.";

        double currentStock = (tankSnap['currentQuantity'] as num).toDouble();
        if (currentStock < sale.soldQuantity) {
          return "Insufficient fuel! Remaining: ${currentStock.toStringAsFixed(2)}L";
        }

        // 3. Update Tank Stock
        transaction.update(tankRef, {
          'currentQuantity': currentStock - sale.soldQuantity,
        });

        // 4. Update Daily History (Aggregation)
        // Map the fuel type to your specific field names
        String fieldName = _getHistoryFieldName(sale.fuelType);
        
        transaction.set(historyRef, {
          'date': Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)),
          fieldName: FieldValue.increment(sale.soldQuantity),
        }, SetOptions(merge: true)); // merge: true creates the doc if it doesn't exist

        // 5. Save individual transaction record
        transaction.set(_salesCollection.doc(), sale.toMap());

        return null; // Success
      });
    } catch (e) {
      return e.toString();
    }
  }

  // Helper to map your Fuel Types to the History Document fields
  String _getHistoryFieldName(String fuelType) {
    switch (fuelType) {
      case 'Auto Diesel': return 'dieselSale';
      case 'Super Diesel': return 'superDieselSale';
      case '92 Petrol': return '92PetrolSale';
      case '95 Petrol': return '95PetrolSale';
      default: return 'otherSale';
    }
  }

  // Get ALL sales for a pumper (Simple Query)
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

  // Get FILTERED sales (Requires Composite Index)
  Stream<List<FuelSaleModel>> getPumperFilteredSales(String pumperId, DateTime startDate) {
    return _firestore
        .collection('fuelSales')
        .where('pumperId', isEqualTo: pumperId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('dateTime', descending: true) 
        .snapshots()
        .map((snapshot) {
          // This print will help you verify if data is arriving after the index is ready
          debugPrint("📊 DATA CHECK: Found ${snapshot.docs.length} records for $pumperId");
          
          return snapshot.docs
              .map((doc) => FuelSaleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
        });
  }
}