// lib/services/prediction_service.dart
// Handles all HTTP calls to the Python prediction API

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';

class PredictionService {
  // ─── API URL CONFIG ─────────────────────────────────────────────────────
  // During local development, use one of these depending on your setup:
  //
  //   Android Emulator  → http://10.0.2.2:8000
  //   iOS Simulator     → http://localhost:8000
  //   Physical device   → http://YOUR_PC_IP:8000
  //                       (find your PC IP: run `ipconfig` on Windows,
  //                        look for IPv4 Address e.g. 192.168.1.105)
  //
  // After deployment to Render:
  //   → https://your-app-name.onrender.com
  //
static const String _baseUrl = 'https://emerald-lanka-prediction-production.up.railway.app';

  static const Duration _timeout = Duration(seconds: 30);

  // ─── MAIN ENDPOINT: loads everything in one call ─────────────────────────
  Future<SummaryResponse> getSummary() async {
    final uri = Uri.parse('$_baseUrl/predict/summary');
    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        return SummaryResponse.fromJson(json.decode(response.body));
      }
      throw Exception('Server error ${response.statusCode}: ${response.body}');
    } on Exception catch (e) {
      throw Exception('Could not reach prediction server.\n\nDetails: $e\n\nMake sure the Python API is running.');
    }
  }

  // ─── HEALTH CHECK ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getHealth() async {
    final uri = Uri.parse('$_baseUrl/health');
    final response = await http.get(uri).timeout(_timeout);
    return json.decode(response.body);
  }

  // ─── TRIGGER RETRAIN ─────────────────────────────────────────────────────
  Future<String> triggerRetrain() async {
    final uri = Uri.parse('$_baseUrl/retrain');
    final response = await http.post(uri).timeout(_timeout);
    final body = json.decode(response.body);
    return body['message'] ?? 'Retrain triggered';
  }
}