class PumperPreferenceModel {
  final String pumperId;
  final String preferredShift;       // "Day Shift" | "Night Shift" | "No Preference"
  final bool allowConsecutiveShifts; // willing to work day + night same day?
  final int maxShiftsPerWeek;        // 1 to 6
  final List<int> daysOff;           // 0=Mon, 1=Tue ... 6=Sun
  final List<String> preferredPumps; // ["Petrol 01", "Diesel 02"] etc.
  final bool isAvailable;            // master toggle — false = exclude from scheduling

  PumperPreferenceModel({
    required this.pumperId,
    required this.preferredShift,
    required this.allowConsecutiveShifts,
    required this.maxShiftsPerWeek,
    required this.daysOff,
    required this.preferredPumps,
    this.isAvailable = true,
  });

  // Convert Firestore document → model
  factory PumperPreferenceModel.fromMap(Map<String, dynamic> map) {
    return PumperPreferenceModel(
      pumperId: map['pumperId'] ?? '',
      preferredShift: map['preferredShift'] ?? 'No Preference',
      allowConsecutiveShifts: map['allowConsecutiveShifts'] ?? false,
      maxShiftsPerWeek: map['maxShiftsPerWeek'] ?? 5,
      daysOff: List<int>.from(map['daysOff'] ?? []),
      preferredPumps: List<String>.from(map['preferredPumps'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  // Convert model → Firestore document
  Map<String, dynamic> toMap() {
    return {
      'pumperId': pumperId,
      'preferredShift': preferredShift,
      'allowConsecutiveShifts': allowConsecutiveShifts,
      'maxShiftsPerWeek': maxShiftsPerWeek,
      'daysOff': daysOff,
      'preferredPumps': preferredPumps,
      'isAvailable': isAvailable,
    };
  }
}