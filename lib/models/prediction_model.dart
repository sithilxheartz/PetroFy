// lib/models/prediction_model.dart
// Data classes that match exactly what the API returns

class FuelPrediction {
  final String date;
  final double predictedLitres;

  FuelPrediction({required this.date, required this.predictedLitres});

  factory FuelPrediction.fromJson(Map<String, dynamic> json) {
    return FuelPrediction(
      date: json['date'] as String,
      predictedLitres: (json['predicted_litres'] as num).toDouble(),
    );
  }
}

class AccuracyNote {
  final double mapePct;
  final String reliability; // "high", "medium", "low"
  final String note;

  AccuracyNote({
    required this.mapePct,
    required this.reliability,
    required this.note,
  });

  factory AccuracyNote.fromJson(Map<String, dynamic> json) {
    return AccuracyNote(
      mapePct: (json['mape_pct'] as num).toDouble(),
      reliability: json['reliability'] as String,
      note: json['note'] as String,
    );
  }
}

class TomorrowData {
  final FuelPrediction petrol;
  final FuelPrediction superPetrol;
  final FuelPrediction diesel;
  final FuelPrediction superDiesel;
  final double totalLitres;

  TomorrowData({
    required this.petrol,
    required this.superPetrol,
    required this.diesel,
    required this.superDiesel,
    required this.totalLitres,
  });

  factory TomorrowData.fromJson(Map<String, dynamic> json) {
    return TomorrowData(
      petrol:      FuelPrediction.fromJson(json['petrol']),
      superPetrol: FuelPrediction.fromJson(json['super_petrol']),
      diesel:      FuelPrediction.fromJson(json['diesel']),
      superDiesel: FuelPrediction.fromJson(json['super_diesel']),
      totalLitres: (json['total_litres'] as num).toDouble(),
    );
  }
}

class SevenDayData {
  final List<FuelPrediction> petrol;
  final List<FuelPrediction> superPetrol;
  final List<FuelPrediction> diesel;
  final List<FuelPrediction> superDiesel;

  SevenDayData({
    required this.petrol,
    required this.superPetrol,
    required this.diesel,
    required this.superDiesel,
  });

  factory SevenDayData.fromJson(Map<String, dynamic> json) {
    List<FuelPrediction> parse(String key) =>
        (json[key] as List).map((e) => FuelPrediction.fromJson(e)).toList();

    return SevenDayData(
      petrol:      parse('petrol'),
      superPetrol: parse('super_petrol'),
      diesel:      parse('diesel'),
      superDiesel: parse('super_diesel'),
    );
  }
}

class SummaryResponse {
  final String generatedAt;
  final String dataAsOf;
  final TomorrowData tomorrow;
  final SevenDayData sevenDays;
  final Map<String, AccuracyNote> accuracyNotes;

  SummaryResponse({
    required this.generatedAt,
    required this.dataAsOf,
    required this.tomorrow,
    required this.sevenDays,
    required this.accuracyNotes,
  });

  factory SummaryResponse.fromJson(Map<String, dynamic> json) {
    final notes = (json['accuracy_notes'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, AccuracyNote.fromJson(v)),
    );
    return SummaryResponse(
      generatedAt: json['generated_at'] as String,
      dataAsOf:    json['data_as_of'] as String,
      tomorrow:    TomorrowData.fromJson(json['tomorrow']),
      sevenDays:   SevenDayData.fromJson(json['seven_days']),
      accuracyNotes: notes,
    );
  }
}

// Fuel type metadata — colours, labels, icons
class FuelMeta {
  static const List<Map<String, dynamic>> fuels = [
    {
      'key':   'petrol',
      'label': 'Petrol',
      'emoji': '⛽',
      'color': 0xFF3B82F6,   // blue
    },
    {
      'key':   'super_petrol',
      'label': 'Super Petrol',
      'emoji': '🔋',
      'color': 0xFF10B981,   // green
    },
    {
      'key':   'diesel',
      'label': 'Diesel',
      'emoji': '🚛',
      'color': 0xFFF59E0B,   // amber
    },
    {
      'key':   'super_diesel',
      'label': 'Super Diesel',
      'emoji': '💎',
      'color': 0xFF8B5CF6,   // purple
    },
  ];
}