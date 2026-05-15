// lib/services/evaporation_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

class FuelEvap {
  final String date;
  final double evapLitres;
  final double evapLkr;
  final double evapPctOfSales;
  final double predictedSalesL;
  final Map<String, dynamic> weather;

  FuelEvap({
    required this.date,
    required this.evapLitres,
    required this.evapLkr,
    required this.evapPctOfSales,
    required this.predictedSalesL,
    required this.weather,
  });

  factory FuelEvap.fromJson(Map<String, dynamic> j) => FuelEvap(
        date:            j['date'] ?? '',
        evapLitres:      (j['evap_litres'] as num?)?.toDouble() ?? 0,
        evapLkr:         (j['evap_lkr'] as num?)?.toDouble() ?? 0,
        evapPctOfSales:  (j['evap_pct_of_sales'] as num?)?.toDouble() ?? 0,
        predictedSalesL: (j['predicted_sales_L'] as num?)?.toDouble() ?? 0,
        weather:         (j['weather'] as Map<String, dynamic>?) ?? {},
      );
}

class EvapSummary {
  final double totalEvapLitres;
  final double totalEvapLkr;
  final double annualEstLitres;
  final double annualEstLkr;

  EvapSummary({
    required this.totalEvapLitres,
    required this.totalEvapLkr,
    required this.annualEstLitres,
    required this.annualEstLkr,
  });

  factory EvapSummary.fromJson(Map<String, dynamic> j) => EvapSummary(
        totalEvapLitres: (j['total_evap_litres'] as num?)?.toDouble() ?? 0,
        totalEvapLkr:    (j['total_evap_lkr'] as num?)?.toDouble() ?? 0,
        annualEstLitres: (j['annual_est_litres'] as num?)?.toDouble() ?? 0,
        annualEstLkr:    (j['annual_est_lkr'] as num?)?.toDouble() ?? 0,
      );
}

class TomorrowEvapData {
  final FuelEvap petrol;
  final FuelEvap superPetrol;
  final FuelEvap diesel;
  final FuelEvap superDiesel;
  final EvapSummary summary;
  final String predictionFor;

  TomorrowEvapData({
    required this.petrol,
    required this.superPetrol,
    required this.diesel,
    required this.superDiesel,
    required this.summary,
    required this.predictionFor,
  });

  factory TomorrowEvapData.fromJson(Map<String, dynamic> j) =>
      TomorrowEvapData(
        petrol:        FuelEvap.fromJson(j['petrol']),
        superPetrol:   FuelEvap.fromJson(j['super_petrol']),
        diesel:        FuelEvap.fromJson(j['diesel']),
        superDiesel:   FuelEvap.fromJson(j['super_diesel']),
        summary:       EvapSummary.fromJson(j['summary']),
        predictionFor: j['prediction_for'] ?? '',
      );
}

class HistoryRecord {
  final String date;
  final double totalEvapL;
  final double totalEvapLkr;
  final double petrolEvapL;
  final double superPetrolEvapL;
  final double dieselEvapL;
  final double superDieselEvapL;
  final double tempMaxC;
  final double precipMm;

  HistoryRecord({
    required this.date,
    required this.totalEvapL,
    required this.totalEvapLkr,
    required this.petrolEvapL,
    required this.superPetrolEvapL,
    required this.dieselEvapL,
    required this.superDieselEvapL,
    required this.tempMaxC,
    required this.precipMm,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> j) => HistoryRecord(
        date:             j['date'] ?? '',
        totalEvapL:       (j['totalEvapL'] as num?)?.toDouble() ?? 0,
        totalEvapLkr:     (j['totalEvapLkr'] as num?)?.toDouble() ?? 0,
        petrolEvapL:      (j['petrolEvapL'] as num?)?.toDouble() ?? 0,
        superPetrolEvapL: (j['superPetrolEvapL'] as num?)?.toDouble() ?? 0,
        dieselEvapL:      (j['dieselEvapL'] as num?)?.toDouble() ?? 0,
        superDieselEvapL: (j['superDieselEvapL'] as num?)?.toDouble() ?? 0,
        tempMaxC:         (j['tempMaxC'] as num?)?.toDouble() ?? 0,
        precipMm:         (j['precipMm'] as num?)?.toDouble() ?? 0,
      );
}

class EvapHistoryData {
  final List<HistoryRecord> records;
  final double periodTotalL;
  final double periodTotalLkr;
  final double annualEstLkr;

  EvapHistoryData({
    required this.records,
    required this.periodTotalL,
    required this.periodTotalLkr,
    required this.annualEstLkr,
  });

  factory EvapHistoryData.fromJson(Map<String, dynamic> j) => EvapHistoryData(
        records:        (j['records'] as List)
            .map((r) => HistoryRecord.fromJson(r))
            .toList(),
        periodTotalL:   (j['period_total_L'] as num?)?.toDouble() ?? 0,
        periodTotalLkr: (j['period_total_lkr'] as num?)?.toDouble() ?? 0,
        annualEstLkr:   (j['annual_est_lkr'] as num?)?.toDouble() ?? 0,
      );
}

// ─── SERVICE ─────────────────────────────────────────────────────────────────

class EvaporationService {
  // ⚠️ Replace with your Railway evaporation API URL
  static const String baseUrl = 'https://fuel-evaporation-predictor-production.up.railway.app';
  static const Duration _timeout = Duration(seconds: 30);

  /// Tomorrow's ML evaporation prediction
  Future<TomorrowEvapData> getTomorrowEvaporation() async {
    final r = await http
        .get(Uri.parse('$baseUrl/predict/evaporation'))
        .timeout(_timeout);
    if (r.statusCode == 200) {
      return TomorrowEvapData.fromJson(json.decode(r.body));
    }
    throw Exception('API error: ${r.statusCode}');
  }

  /// Historical evaporation from Firebase (via API)
  Future<EvapHistoryData> getHistory({int days = 60}) async {
    final r = await http
        .get(Uri.parse('$baseUrl/evaporation/history?days=$days'))
        .timeout(_timeout);
    if (r.statusCode == 200) {
      return EvapHistoryData.fromJson(json.decode(r.body));
    }
    throw Exception('History API error: ${r.statusCode}');
  }

  /// Trigger retrain — auto-stores all data to Firebase after training
  Future<String> triggerRetrain() async {
    final r = await http
        .post(Uri.parse('$baseUrl/retrain'))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) {
      final body = json.decode(r.body);
      return body['message'] ?? 'Retrain started';
    }
    throw Exception('Retrain failed: ${r.statusCode}');
  }
}