import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pumper_preference_model.dart';

class PreferenceService {
  // Each pumper has ONE preference document, stored by their uid
  final CollectionReference _prefCollection =
      FirebaseFirestore.instance.collection('pumperPreferences');

  // Save or update preferences for a pumper
  Future<String?> savePreferences(PumperPreferenceModel prefs) async {
    try {
      await _prefCollection.doc(prefs.pumperId).set(prefs.toMap());
      return null; // success
    } catch (e) {
      return "Failed to save: ${e.toString()}";
    }
  }

  // Get preferences for a single pumper (used on their settings page)
  Future<PumperPreferenceModel?> getPreferences(String pumperId) async {
    try {
      final doc = await _prefCollection.doc(pumperId).get();
      if (!doc.exists) return null;
      return PumperPreferenceModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}