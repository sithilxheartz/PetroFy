// lib/screens/dashboard_screen.dart
// Fuel Prediction Dashboard — uses exact Petrofy AppColors

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../models/prediction_model.dart';
import '../services/prediction_service.dart';

// ── Exact AppColors from your codebase ────────────────────────────────────────
class _C {
  static const background = Color(0xFF0B0D0C); // Near Black
  static const surface = Color(0xFF161B19); // Dark Grey-Green
  static const primaryGreen = Color(0xFF00FF88); // Glowing Green
  static const secondaryGreen = Color(0xFF00A35C); // Deep Forest Green
  static const textMain = Color(0xFFFFFFFF);
  static const textDim = Color(0xFF9E9E9E);
  static const error = Color(0xFFFF5252);
  static const warning = Color(0xFFFFAB40);

  // Extra fuel-type colors (complementary to your palette)
  static const blue = Color(0xFF40C4FF); // petrol
  static const amber = Color(0xFFFFAB40); // diesel  (reuses warning)
  static const purple = Color(0xFFCE93D8); // super diesel
  static const orange = Color(0xFFFF6D00); // low-accuracy indicator
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _service = PredictionService();
  late TabController _tabs;

  SummaryResponse? _data;
  bool _loading = true;
  String? _error;

  // Fuel config — label, icon, color, accuracy badge
  static const _fuels = [
    {
      'key': 'petrol',
      'label': 'Petrol',
      'icon': '⚡',
      'color': _C.blue,
      'mape': '±7%',
      'rel': 'high',
    },
    {
      'key': 'diesel',
      'label': 'Diesel',
      'icon': '🛢️',
      'color': _C.amber,
      'mape': '±14%',
      'rel': 'medium',
    },
    {
      'key': 'super_diesel',
      'label': 'Super Diesel',
      'icon': '🛢️',
      'color': _C.purple,
      'mape': '±63%',
      'rel': 'low',
    },
    {
      'key': 'super_petrol',
      'label': 'Super Petrol',
      'icon': '⚡',
      'color': _C.primaryGreen,
      'mape': '±50%',
      'rel': 'low',
    },
  ];

  FuelPrediction _getPred(String key) {
    final t = _data!.tomorrow;
    switch (key) {
      case 'petrol':
        return t.petrol;
      case 'super_petrol':
        return t.superPetrol;
      case 'diesel':
        return t.diesel;
      default:
        return t.superDiesel;
    }
  }

  List<FuelPrediction> _get7Day(String key) {
    final s = _data!.sevenDays;
    switch (key) {
      case 'petrol':
        return s.petrol;
      case 'super_petrol':
        return s.superPetrol;
      case 'diesel':
        return s.diesel;
      default:
        return s.superDiesel;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getSummary();
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── ROOT BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      extendBodyBehindAppBar: true,
      appBar: _appBar(),
      body: Stack(
        children: [
          // Subtle background glow — matches your FuelLevelDashboard style
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.primaryGreen.withOpacity(0.05),
              ),
            ),
          ),
          _loading
              ? _skeleton()
              : _error != null
              ? _errorView()
              : TabBarView(
                  controller: _tabs,
                  children: [_tomorrowTab(), _sevenDayTab()],
                ),
        ],
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: _C.background.withOpacity(0.5),
    elevation: 0,
    title: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _C.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.primaryGreen.withOpacity(0.2)),
          ),
          child: Icon(Icons.insights),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FUEL SALES PREDICTOR',
              style: TextStyle(
             //   color: _C.primaryGreen,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const Text(
              'EMERALD LANKA FILLING STATION',
              style: TextStyle(color: _C.textDim, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh_rounded, color: _C.primaryGreen),
        onPressed: _loading ? null : _load,
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: _C.textDim),
        color: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (v) {
          if (v == 'retrain') _retrainDialog();
          if (v == 'about') _aboutDialog();
        },
        itemBuilder: (_) => [
          _pop('retrain', Icons.model_training_rounded, 'Retrain Models'),
          _pop('about', Icons.info_outline_rounded, 'About'),
        ],
      ),
      const SizedBox(width: 4),
    ],
    bottom: TabBar(
      controller: _tabs,
      indicatorColor: _C.primaryGreen,
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: _C.primaryGreen,
      unselectedLabelColor: _C.textDim,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
      tabs: const [
        Tab(
          icon: Icon(Icons.calendar_today_rounded, size: 15),
          text: 'TOMORROW',
        ),
        Tab(icon: Icon(Icons.show_chart_rounded, size: 15), text: '7 DAYS'),
      ],
    ),
  );

  PopupMenuItem<String> _pop(String v, IconData icon, String label) =>
      PopupMenuItem(
        value: v,
        child: Row(
          children: [
            Icon(icon, color: _C.primaryGreen, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: _C.textMain, fontSize: 14),
            ),
          ],
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 1 — TOMORROW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _tomorrowTab() {
    final t = _data!.tomorrow;
    final date = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(DateTime.parse(t.petrol.date));

    return RefreshIndicator(
      onRefresh: _load,
      color: _C.primaryGreen,
      backgroundColor: _C.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 175, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date chip ──────────────────────────────────────────────────────
            _card(
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: _C.primaryGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      date,
                      style: const TextStyle(
                        color: _C.textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _pill('Updated ${_data!.dataAsOf}', _C.primaryGreen),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Total banner ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A35C), Color(0xFF00FF88)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                //   boxShadow: [
                //    BoxShadow(
                //      color: _C.primaryGreen.withOpacity(0.25),
                //     blurRadius: 20,
                //     offset: const Offset(0, 6),
                //     ),
                //    ],
              ),
              child: Column(
                children: [
                  Text(
                    'Total Predicted Sales Tomorrow',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 0),
                  Text(
                    '${NumberFormat('#,##0.0').format(t.totalLitres)} L',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),
            _sLabel('FUEL BREAKDOWN'),
            const SizedBox(height: 15),

            // ── Fuel cards ─────────────────────────────────────────────────────
            ..._fuels.map((f) {
              final key = f['key'] as String;
              final color = f['color'] as Color;
              final pred = _getPred(key);
              final isLow = f['rel'] == 'low';
              return _fuelCard(
                icon: f['icon'] as String,
                label: f['label'] as String,
                litres: pred.predictedLitres,
                color: color,
                mape: f['mape'] as String,
                rel: f['rel'] as String,
                isLow: isLow,
              );
            }),

            const SizedBox(height: 5),

            // ── Accuracy guide ─────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sLabel('ACCURACY GUIDE'),
                  const SizedBox(height: 12),
                  _guideRow('🛢️ Petrol', '±7%', _C.blue, 'Very reliable'),
                  _guideRow('🚛 Diesel', '±14%', _C.amber, 'Good for planning'),
                  _guideRow(
                    '⚡ Super Petrol',
                    '±50%',
                    _C.warning,
                    'Rough estimate',
                  ),
                  _guideRow(
                    '💎 Super Diesel',
                    '±63%',
                    _C.warning,
                    'Rough estimate',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Low accuracy for super fuels is due to frequent out-of-stock '
                    'events. Improves as you add more monthly data.',
                    style: TextStyle(
                      color: _C.textDim,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 35),
          ],
        ),
      ),
    );
  }

  Widget _fuelCard({
    required String icon,
    required String label,
    required double litres,
    required Color color,
    required String mape,
    required String rel,
    required bool isLow,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLow ? _C.warning.withOpacity(0.15) : color.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon circle — matches your _buildTankCard / _buildMenuButton style
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _C.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,##0.0').format(litres)} L',
                      style: TextStyle(
                        color: color,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              _badge(mape, rel),
            ],
          ),

          // Warning banner for low-accuracy fuels
          if (isLow) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _C.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.warning.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _C.warning,
                    size: 15,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rough estimate — high OOS days in training data',
                      style: TextStyle(color: _C.warning, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 2 — 7 DAYS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _sevenDayTab() {
    final sd = _data!.sevenDays;
    return RefreshIndicator(
      onRefresh: _load,
      color: _C.primaryGreen,
      backgroundColor: _C.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 175, 20, 120),
        child: Column(
          children: [
            _overviewBar(sd),
            const SizedBox(height: 14),
            ..._fuels.map(
              (f) => _lineCard(
                icon: f['icon'] as String,
                label: f['label'] as String,
                preds: _get7Day(f['key'] as String),
                color: f['color'] as Color,
                mape: f['mape'] as String,
                rel: f['rel'] as String,
              ),
            ),
                            SizedBox(height: 20,)
          ],
        ),
      ),
    );
  }

  Widget _overviewBar(SevenDayData sd) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sLabel('7-DAY TOTAL OVERVIEW'),
          const SizedBox(height: 4),
          const Text(
            'All fuel types combined',
            style: TextStyle(color: _C.textDim, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (v, _) => Text(
                        '${(v / 1000).toStringAsFixed(1)}k',
                        style: const TextStyle(color: _C.textDim, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= sd.petrol.length)
                          return const SizedBox();
                        final d = DateTime.parse(sd.petrol[i].date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('dd\nEEE').format(d),
                            style: const TextStyle(
                              color: _C.textDim,
                              fontSize: 9,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(sd.petrol.length, (i) {
                  final total =
                      sd.petrol[i].predictedLitres +
                      sd.superPetrol[i].predictedLitres +
                      sd.diesel[i].predictedLitres +
                      sd.superDiesel[i].predictedLitres;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: total,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00A35C), Color(0xFF00FF88)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 28,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _C.surface,
                    getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                      '${NumberFormat('#,##0').format(rod.toY)} L',
                      const TextStyle(
                        color: _C.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineCard({
    required String icon,
    required String label,
    required List<FuelPrediction> preds,
    required Color color,
    required String mape,
    required String rel,
  }) {
    final spots = preds
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.predictedLitres))
        .toList();
    final maxY = preds
        .map((p) => p.predictedLitres)
        .reduce((a, b) => a > b ? a : b);
    final minY = preds
        .map((p) => p.predictedLitres)
        .reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _badge(mape, rel),
              ],
            ),

            const SizedBox(height: 18),

            // Line chart
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  minY: (minY * 0.88).floorToDouble(),
                  maxY: (maxY * 1.12).ceilToDouble(),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        getTitlesWidget: (v, _) => Text(
                          '${(v / 1000).toStringAsFixed(1)}k',
                          style: const TextStyle(
                            color: _C.textDim,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= preds.length)
                            return const SizedBox();
                          final d = DateTime.parse(preds[i].date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('dd\nEEE').format(d),
                              style: const TextStyle(
                                color: _C.textDim,
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: _C.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.18),
                            color.withOpacity(0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => _C.surface,
                      getTooltipItems: (s) => s
                          .map(
                            (sp) => LineTooltipItem(
                              '${NumberFormat('#,##0.0').format(sp.y)} L',
                              TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Data rows — matches your _buildTankCard footer style
            ...preds.map((p) {
              final d = DateTime.parse(p.date);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('EEE, d MMM').format(d),
                        style: const TextStyle(color: _C.textDim, fontSize: 12),
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,##0.0').format(p.predictedLitres)} L',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SKELETON
  // ══════════════════════════════════════════════════════════════════════════

  Widget _skeleton() => Shimmer.fromColors(
    baseColor: _C.surface,
    highlightColor: const Color(0xFF1F2824),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 175, 20, 20),
      child: Column(
        children: [
          _skelBox(56),
          const SizedBox(height: 12),
          _skelBox(112),
          const SizedBox(height: 12),
          _skelBox(90),
          const SizedBox(height: 12),
          _skelBox(90),
          const SizedBox(height: 12),
          _skelBox(90),
          const SizedBox(height: 12),
          _skelBox(90),
        ],
      ),
    ),
  );

  Widget _skelBox(double h) => Container(
    height: h,
    width: double.infinity,
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(24),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  ERROR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.error.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _C.error.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: _C.error,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cannot reach prediction server',
            style: TextStyle(
              color: _C.textMain,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              _error ?? '',
              style: const TextStyle(color: _C.textDim, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primaryGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  DIALOGS
  // ══════════════════════════════════════════════════════════════════════════

  void _retrainDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.model_training_rounded, color: _C.primaryGreen),
            SizedBox(width: 10),
            Text(
              'Retrain Models',
              style: TextStyle(color: _C.textMain, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Fetches the latest data from Firebase fuelSaleHistory and '
          'retrains all 4 prediction models.\n\n'
          'Runs in the background — takes 2–3 minutes. '
          'Predictions update automatically when done.',
          style: TextStyle(color: _C.textDim, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _C.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final msg = await _service.triggerRetrain();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: _C.secondaryGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: _C.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Start Retraining'),
          ),
        ],
      ),
    );
  }

  void _aboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'About',
          style: TextStyle(color: _C.textMain, fontWeight: FontWeight.bold),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.primaryGreen.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.primaryGreen.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⛽ Emerald Lanka Fuel Prediction',
                style: TextStyle(
                  color: _C.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              _aRow('Station', 'Emerald Lanka, Hettipola'),
              _aRow('Models', '4 × XGBoost'),
              _aRow('Features', '48 engineered'),
              _aRow('Data up to', _data?.dataAsOf ?? '-'),
              _aRow('Petrol', '±11.78% CV MAPE'),
              _aRow('Diesel', '±17.39% CV MAPE'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.primaryGreen.withOpacity(0.07), width: 1.5),
    ),
    child: child,
  );

  Widget _sLabel(String t) => Text(
    t,
    style: const TextStyle(
      color: _C.primaryGreen,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
    ),
  );

  Widget _pill(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withOpacity(0.3)),
    ),
    child: Text(
      t,
      style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );

  Widget _badge(String mape, String rel) {
    final c = rel == 'high'
        ? _C.primaryGreen
        : rel == 'medium'
        ? _C.warning
        : _C.error;
    return _pill(mape, c);
  }

  Widget _guideRow(String label, String pct, Color c, String desc) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: _C.textMain, fontSize: 12),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: c.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            pct,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(desc, style: const TextStyle(color: _C.textDim, fontSize: 11)),
      ],
    ),
  );

  Widget _aRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            l,
            style: const TextStyle(color: _C.textDim, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(
              color: _C.textMain,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
