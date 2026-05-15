import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/fuel_sale_model.dart';

class SalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _salesCollection =
      FirebaseFirestore.instance.collection('fuelSales');
  final CollectionReference _tanksCollection =
      FirebaseFirestore.instance.collection('fuelTanks');
  final CollectionReference _historyCollection =
      FirebaseFirestore.instance.collection('fuelSaleHistory');

  // ⚠️ Replace with your Railway evaporation API URL
  static const String _evapApiUrl =
      'https://fuel-evaporation-predictor-production.up.railway.app';

  // ─── RECORD SALE ───────────────────────────────────────────────────────────

  Future<String?> recordSale(FuelSaleModel sale) async {
    try {
      DocumentReference tankRef    = _tanksCollection.doc(sale.tankId);
      String            todayId    = DateFormat('yyyy-MM-dd').format(DateTime.now());
      DocumentReference historyRef = _historyCollection.doc(todayId);

      String? transactionError = await _firestore.runTransaction((transaction) async {
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
          'date': Timestamp.fromDate(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          )),
          fieldName: FieldValue.increment(sale.soldQuantity),
        }, SetOptions(merge: true));

        // 4. Save Individual Transaction
        transaction.set(_salesCollection.doc(), sale.toMap());

        return null; // Success
      });

      // ── If transaction succeeded, update evaporation in background ─────────
      // We do this AFTER the Firestore transaction completes so we have
      // the latest aggregated sales totals for today.
      if (transactionError == null) {
        _updateEvaporationForToday(todayId);
      }

      return transactionError;

    } catch (e) {
      return e.toString();
    }
  }

  // ─── UPDATE EVAPORATION (called after every sale) ─────────────────────────

  /// Fetches today's latest sales totals from fuelSaleHistory,
  /// then calls the Railway API to recalculate and store evaporation.
  /// Runs in background — does NOT block the sale from completing.
  Future<void> _updateEvaporationForToday(String dateId) async {
    try {
      // Small delay to ensure Firestore has committed the latest totals
      await Future.delayed(const Duration(milliseconds: 500));

      // Get today's latest aggregated sales from fuelSaleHistory
      final doc = await _historyCollection.doc(dateId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      // Build request body with today's sales
      // null means that fuel has no sales recorded yet
      final body = {
        'date':         dateId,
        'petrol':       _safeDouble(data['92PetrolSale']),
        'super_petrol': _safeDouble(data['95PetrolSale']),
        'diesel':       _safeDouble(data['dieselSale']),
        'super_diesel': _safeDouble(data['superDieselSale']),
      };

      // Call Railway evaporation API
      await http.post(
        Uri.parse('$_evapApiUrl/evaporation/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

    } catch (e) {
      // Silent fail — evaporation update is best-effort
      // The sale is already recorded successfully
      // User can tap Retrain later if needed
      print('Evaporation update failed (non-critical): $e');
    }
  }

  double? _safeDouble(dynamic v) {
    if (v == null) return null;
    try {
      final f = double.parse(v.toString());
      return f > 0 ? f : null;
    } catch (_) {
      return null;
    }
  }

  // ─── ADMIN APPROVAL LOGIC ─────────────────────────────────────────────────

  Future<void> approvePayment(
    String saleId,
    String adminId,
    String adminName,
  ) async {
    await _salesCollection.doc(saleId).update({
      'status':               'payment received',
      'paymentReceiverId':    adminId,
      'paymentReceiverName':  adminName,
    });
  }

  Future<void> moveToSafe(String saleId) async {
    await _salesCollection.doc(saleId).update({'status': 'added to safe'});
  }

  Future<void> updatePaymentStatus({
    required String saleId,
    required String newStatus,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _firestore.collection('fuelSales').doc(saleId).update({
        'status':              newStatus,
        'paymentReceiverId':   adminId,
        'paymentReceiverName': adminName,
        'approvalTime':        FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to update status: $e");
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  String _getHistoryFieldName(String fuelType) {
    switch (fuelType) {
      case 'Auto Diesel':  return 'dieselSale';
      case 'Super Diesel': return 'superDieselSale';
      case '92 Petrol':    return '92PetrolSale';
      case '95 Petrol':    return '95PetrolSale';
      default:             return 'otherSale';
    }
  }

  // ─── QUERY METHODS ────────────────────────────────────────────────────────

  Stream<List<FuelSaleModel>> getPumperSales(String pumperId) {
    return _firestore
        .collection('fuelSales')
        .where('pumperId', isEqualTo: pumperId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FuelSaleModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  Stream<List<FuelSaleModel>> getPumperFilteredSales(
    String pumperId,
    DateTime startDate,
  ) {
    return _firestore
        .collection('fuelSales')
        .where('pumperId', isEqualTo: pumperId)
        .where('dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FuelSaleModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }
}