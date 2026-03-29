import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_model.dart';

class ShiftService {
  final CollectionReference _shiftCollection = FirebaseFirestore.instance.collection('shiftSchedule');

  // Logic: Prevent double booking of the same pump on the same shift/date
  Future<String?> requestShift(ShiftModel shift) async {
    try {
      // 1. Check if this specific pump is already taken for this date and shift
      final QuerySnapshot existing = await _shiftCollection
          .where('date', isEqualTo: Timestamp.fromDate(shift.date))
          .where('shiftType', isEqualTo: shift.shiftType)
          .where('pumpNumber', isEqualTo: shift.pumpNumber)
          .get();

      if (existing.docs.isNotEmpty) {
        return "This pump is already booked for the ${shift.shiftType} shift on this date.";
      }

      // 2. If clear, add the request
      await _shiftCollection.add(shift.toMap());
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }
  
  // Get all shifts for the admin approval page
  Stream<List<ShiftModel>> getAllShifts() {
    return _shiftCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}