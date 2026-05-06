import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_model.dart';

class ShiftService {
  final CollectionReference _shiftCollection = FirebaseFirestore.instance.collection('shiftSchedule');

Future<String?> requestShift(ShiftModel shift) async {
  try {
    // ← changed to UTC midnight
    DateTime normalizedDate = DateTime.utc(
      shift.date.year, shift.date.month, shift.date.day,
    );
    Timestamp dateTimestamp = Timestamp.fromDate(normalizedDate);

      // --- CONSTRAINT 1: Is this specific PUMP already taken by SOMEONE ELSE? ---
      final QuerySnapshot pumpTaken = await _shiftCollection
          .where('date', isEqualTo: dateTimestamp)
          .where('shiftType', isEqualTo: shift.shiftType)
          .where('pumpNumber', isEqualTo: shift.pumpNumber)
          .get();

      if (pumpTaken.docs.isNotEmpty) {
        return "This pump is already assigned to someone else for the ${shift.shiftType}.";
      }

      // --- CONSTRAINT 2: Has THIS PUMPER already booked a different pump? ---
      final QuerySnapshot pumperAlreadyBooked = await _shiftCollection
          .where('pumperId', isEqualTo: shift.pumperId)
          .where('date', isEqualTo: dateTimestamp)
          .where('shiftType', isEqualTo: shift.shiftType)
          .get();

      if (pumperAlreadyBooked.docs.isNotEmpty) {
        return "You have already reserved a pump for the ${shift.shiftType} on this date.";
      }

      // 3. If both checks pass, save the shift as 'accepted'
      Map<String, dynamic> shiftData = shift.toMap();
      shiftData['status'] = 'accepted';
      shiftData['date'] = dateTimestamp;

      await _shiftCollection.add(shiftData);
      return null; // Success
    } catch (e) {
      return "Connection Error: ${e.toString()}";
    }
  }
// Stream for the Roster View
Stream<List<ShiftModel>> getShiftsByDate(DateTime date) {
  // ← changed to UTC to match what Cloud Function wrote
  DateTime searchDate = DateTime.utc(date.year, date.month, date.day);

  return _shiftCollection
      .where('date', isEqualTo: Timestamp.fromDate(searchDate))
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => ShiftModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList());
}

// Stream for My Schedule (pumper's own shifts)
Stream<List<ShiftModel>> getShiftsReport({
  required String pumperId,
  required DateTime startDate,
  required DateTime endDate,
}) {
  // ← changed to UTC
  DateTime start = DateTime.utc(startDate.year, startDate.month, startDate.day);
  DateTime end = DateTime.utc(endDate.year, endDate.month, endDate.day, 23, 59, 59);

  return _shiftCollection
      .where('pumperId', isEqualTo: pumperId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => ShiftModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList());
}
}