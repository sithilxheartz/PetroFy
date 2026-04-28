import 'package:cloud_functions/cloud_functions.dart';

class ScheduleService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> generateSchedule(DateTime weekStart) async {
    try {
      // Format date as "2025-01-20" string to send to Cloud Function
      final String dateStr =
          "${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}";

      final HttpsCallable callable =
          _functions.httpsCallable('generateWeeklySchedule');

      final result = await callable.call({'startDate': dateStr});

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Something went wrong.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}