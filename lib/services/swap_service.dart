import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/swap_request_model.dart';
import '../models/shift_model.dart';

class SwapService {
  final CollectionReference _swapCollection =
      FirebaseFirestore.instance.collection('swapRequests');
  final CollectionReference _shiftCollection =
      FirebaseFirestore.instance.collection('shiftSchedule');

  // Send a swap request from Pumper A to Pumper B
  Future<String?> sendSwapRequest(SwapRequestModel request) async {
    try {
      // Check no pending swap already exists for requester's shift
      final existing = await _swapCollection
          .where('requesterShiftId', isEqualTo: request.requesterShiftId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existing.docs.isNotEmpty) {
        return "You already have a pending swap request for this shift.";
      }

      await _swapCollection.add(request.toMap());
      return null; // success
    } catch (e) {
      return "Failed to send request: ${e.toString()}";
    }
  }

  // Get all INCOMING swap requests for a pumper (they are the target)
  Stream<List<SwapRequestModel>> getIncomingRequests(String pumperId) {
    return _swapCollection
        .where('targetId', isEqualTo: pumperId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SwapRequestModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get all OUTGOING swap requests a pumper has sent
  Stream<List<SwapRequestModel>> getOutgoingRequests(String pumperId) {
    return _swapCollection
        .where('requesterId', isEqualTo: pumperId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SwapRequestModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Pumper B accepts → swap the shifts in Firestore automatically
  Future<String?> acceptSwap(SwapRequestModel request) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Swap pump numbers between the two shifts
      final requesterShiftRef =
          _shiftCollection.doc(request.requesterShiftId);
      final targetShiftRef =
          _shiftCollection.doc(request.targetShiftId);

      // Pumper A gets Pumper B's pump + shift type
      batch.update(requesterShiftRef, {
        'pumperId': request.targetId,
        'pumperName': request.targetName,
      });

      // Pumper B gets Pumper A's pump + shift type
      batch.update(targetShiftRef, {
        'pumperId': request.requesterId,
        'pumperName': request.requesterName,
      });

      // Mark swap request as accepted
      batch.update(_swapCollection.doc(request.id), {
        'status': 'accepted',
      });

      await batch.commit();
      return null; // success
    } catch (e) {
      return "Failed to accept swap: ${e.toString()}";
    }
  }

  // Pumper B rejects the request
  Future<String?> rejectSwap(String swapRequestId) async {
    try {
      await _swapCollection.doc(swapRequestId).update({'status': 'rejected'});
      return null;
    } catch (e) {
      return "Failed to reject swap: ${e.toString()}";
    }
  }

// FIXED - uses UTC midnight to match Cloud Function
Future<List<ShiftModel>> getShiftsOnDate(DateTime date) async {
  final midnight = DateTime.utc(date.year, date.month, date.day); // ← only change

  print("🔍 Swap: searching shifts on $midnight"); // debug line

  final snap = await _shiftCollection
      .where('date', isEqualTo: Timestamp.fromDate(midnight))
      .get();

  print("📦 Swap: found ${snap.docs.length} shifts"); // debug line

  return snap.docs
      .map((doc) => ShiftModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
}