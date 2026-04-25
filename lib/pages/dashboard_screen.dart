// lib/screens/dashboard_screen.dart
// Matches exact Petrofy app structure:
//   - Same AppBar style as FuelLevelDashboard & AdminLubricantListPage
//   - Same SafeArea + Column body pattern as AdminLubricantListPage
//   - Same card style, border radius, colors as your existing screens
//   - Same background glow circles
//   - No manual padding hacks — uses SafeArea correctly

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../models/prediction_model.dart';
import '../services/prediction_service.dart';
import '../utils/app_colors.dart'; // ← uses YOUR AppColors directly

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
  bool    _loading = true;
  String? _error;

  // Fuel config
  static const _fuels = [
    {
      'key': 'petrol',       'label': '92 Petrol',
      'icon': '🛢️',          'color': Color(0xFF40C4FF),
      'mape': '±7%',         'rel': 'high',
    },
    {
      'key': 'super_petrol', 'label': '95 Petrol',
      'icon': '⚡',           'color': AppColors.primaryGreen,
      'mape': '±50%',        'rel': 'low',
    },
    {
      'key': 'diesel',       'label': 'Auto Diesel',
      'icon': '🚛',           'color': AppColors.warning,
      'mape': '±14%',        'rel': 'medium',
    },
    {
      'key': 'super_diesel', 'label': 'Super Diesel',
      'icon': '💎',           'color': Color(0xFFCE93D8),
      'mape': '±63%',        'rel': 'low',
    },
  ];

  FuelPrediction _getPred(String key) {
    final t = _data!.tomorrow;
    switch (key) {
      case 'petrol':       return t.petrol;
      case 'super_petrol': return t.superPetrol;
      case 'diesel':       return t.diesel;
      default:             return t.superDiesel;
    }
  }

  List<FuelPrediction> _get7Day(String key) {
    final s = _data!.sevenDays;
    switch (key) {
      case 'petrol':       return s.petrol;
      case 'super_petrol': return s.superPetrol;
      case 'diesel':       return s.diesel;
      default:             return s.superDiesel;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getSummary();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ROOT BUILD — mirrors FuelLevelDashboard structure exactly
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // ── Matches your "FUEL INVENTORY" / "PRODUCT INVENTORY" AppBar exactly
        title: const Text(
          'FUEL SALES PREDICTOR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
            fontSize: 21,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.primaryGreen),
            onPressed: _loading ? null : _load,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textDim),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            onSelected: (v) {
              if (v == 'retrain') _retrainDialog();
              if (v == 'about')   _aboutDialog();
            },
            itemBuilder: (_) => [
              _pop('retrain', Icons.model_training_rounded, 'Retrain Models'),
              _pop('about',   Icons.info_outline_rounded,   'About'),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textDim,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_today_rounded, size: 15),
              text: 'TOMORROW',
            ),
            Tab(
              icon: Icon(Icons.show_chart_rounded, size: 15),
              text: '7 DAYS',
            ),
          ],
        ),
      ),

      // ── Body: same Stack + SafeArea pattern as AdminLubricantListPage ──────
      body: Stack(
        children: [
          // Background glow — matches your FuelLevelDashboard & AdminLubricantListPage
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withOpacity(0.05),
              ),
            ),
          ),

          // ── SafeArea wraps everything — no manual padding needed ───────────
          SafeArea(
            child: _loading
                ? _skeleton()
                : _error != null
                    ? _errorView()
                    : TabBarView(
                        controller: _tabs,
                        children: [_tomorrowTab(), _sevenDayTab()],
                      ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _pop(String v, IconData icon, String label) =>
      PopupMenuItem(
        value: v,
        child: Row(children: [
          Icon(icon, color: AppColors.primaryGreen, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: AppColors.textMain, fontSize: 14)),
        ]),
      );

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 1 — TOMORROW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _tomorrowTab() {
    final t    = _data!.tomorrow;
    final date = DateFormat('EEEE, d MMMM yyyy')
        .format(DateTime.parse(t.petrol.date));

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryGreen,
      backgroundColor: AppColors.surface,
      child: ListView(
        // Same bottom padding as FuelLevelDashboard (140 for floating nav)
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 140),
        children: [

          // ── Date chip ──────────────────────────────────────────────────────
          _card(child: Row(children: [
            const Icon(Icons.calendar_today_rounded,
                color: AppColors.primaryGreen, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(date,
                style: const TextStyle(
                    color: AppColors.textMain, fontSize: 14,
                    fontWeight: FontWeight.w600))),
            _pill('Updated ${_data!.dataAsOf}', AppColors.primaryGreen),
          ])),

          const SizedBox(height: 14),

          // ── Total banner ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondaryGreen, AppColors.primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.25),
                  blurRadius: 24, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(children: [
              Text('Total Predicted Sales Tomorrow',
                  style: TextStyle(
                      color: Colors.black.withOpacity(0.65),
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                '${NumberFormat('#,##0.0').format(t.totalLitres)} L',
                style: const TextStyle(
                    color: Colors.black, fontSize: 42,
                    fontWeight: FontWeight.bold, letterSpacing: -1),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Section label — matches yours exactly ──────────────────────────
          _sLabel('FUEL BREAKDOWN'),
          const SizedBox(height: 12),

          // ── Fuel cards ─────────────────────────────────────────────────────
          ..._fuels.map((f) {
            final key   = f['key']   as String;
            final color = f['color'] as Color;
            final pred  = _getPred(key);
            final isLow = f['rel'] == 'low';
            return _fuelCard(
              icon:   f['icon']  as String,
              label:  f['label'] as String,
              litres: pred.predictedLitres,
              color:  color,
              mape:   f['mape']  as String,
              rel:    f['rel']   as String,
              isLow:  isLow,
            );
          }),

          const SizedBox(height: 4),

          // ── Accuracy guide ─────────────────────────────────────────────────
          _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sLabel('ACCURACY GUIDE'),
              const SizedBox(height: 12),
              _guideRow('🛢️ 92 Petrol',    '±7%',  const Color(0xFF40C4FF), 'Very reliable'),
              _guideRow('🚛 Auto Diesel',   '±14%', AppColors.warning,       'Good for planning'),
              _guideRow('⚡ 95 Petrol',     '±50%', AppColors.warning,       'Rough estimate'),
              _guideRow('💎 Super Diesel',  '±63%', AppColors.error,         'Rough estimate'),
              const SizedBox(height: 10),
              const Text(
                'Low accuracy for super fuels is due to frequent out-of-stock '
                'events. Improves as you add more monthly data.',
                style: TextStyle(
                    color: AppColors.textDim, fontSize: 11, height: 1.5),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _fuelCard({
    required String icon,   required String label,
    required double litres, required Color  color,
    required String mape,   required String rel,
    required bool   isLow,
  }) {
    // ── Same structure as your _buildTankCard ──────────────────────────────
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLow
              ? AppColors.warning.withOpacity(0.15)
              : color.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(children: [
          // Icon circle — matches your _buildMenuButton icon style
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 15),

          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text('Predicted Tomorrow',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textDim,
                      fontWeight: FontWeight.bold)),
            ],
          )),

          _badge(mape, rel),
        ]),

        const SizedBox(height: 12),

        // Litres display — same as "Current Stock: X L"
        Text(
          '${NumberFormat('#,##0.0').format(litres)} L',
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold,
              color: color, letterSpacing: -0.5),
        ),

        // Warning for low-accuracy fuels
        if (isLow) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.25)),
            ),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 15),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Rough estimate — high OOS days in training data',
                style: TextStyle(color: AppColors.warning, fontSize: 11),
              )),
            ]),
          ),
        ],
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 2 — 7 DAYS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _sevenDayTab() {
    final sd = _data!.sevenDays;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryGreen,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 140),
        children: [
          _overviewBar(sd),
          const SizedBox(height: 14),
          ..._fuels.map((f) => _lineCard(
            icon:  f['icon']  as String,
            label: f['label'] as String,
            preds: _get7Day(f['key'] as String),
            color: f['color'] as Color,
            mape:  f['mape']  as String,
            rel:   f['rel']   as String,
          )),
        ],
      ),
    );
  }

  Widget _overviewBar(SevenDayData sd) {
    return _card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sLabel('7-DAY TOTAL OVERVIEW'),
        const SizedBox(height: 4),
        const Text('All fuel types combined',
            style: TextStyle(color: AppColors.textDim, fontSize: 12)),
        const SizedBox(height: 20),
        SizedBox(height: 170, child: BarChart(BarChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 46,
              getTitlesWidget: (v, _) => Text(
                '${(v / 1000).toStringAsFixed(1)}k',
                style: const TextStyle(
                    color: AppColors.textDim, fontSize: 10),
              ),
            )),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= sd.petrol.length) return const SizedBox();
                final d = DateTime.parse(sd.petrol[i].date);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat('dd\nEEE').format(d),
                    style: const TextStyle(
                        color: AppColors.textDim, fontSize: 9),
                    textAlign: TextAlign.center),
                );
              },
            )),
          ),
          barGroups: List.generate(sd.petrol.length, (i) {
            final total = sd.petrol[i].predictedLitres
                + sd.superPetrol[i].predictedLitres
                + sd.diesel[i].predictedLitres
                + sd.superDiesel[i].predictedLitres;
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: total,
                gradient: const LinearGradient(
                  colors: [AppColors.secondaryGreen, AppColors.primaryGreen],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 30,
                borderRadius: BorderRadius.circular(8),
              ),
            ]);
          }),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                '${NumberFormat('#,##0').format(rod.toY)} L',
                const TextStyle(color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ))),
      ],
    ));
  }

  Widget _lineCard({
    required String icon,  required String label,
    required List<FuelPrediction> preds,
    required Color color,  required String mape,
    required String rel,
  }) {
    final spots = preds.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.predictedLitres))
        .toList();
    final maxY = preds.map((p) => p.predictedLitres)
        .reduce((a, b) => a > b ? a : b);
    final minY = preds.map((p) => p.predictedLitres)
        .reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: color.withOpacity(0.1), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header — same as _buildTankCard title row
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: color))),
          _badge(mape, rel),
        ]),

        const SizedBox(height: 18),

        // Line chart
        SizedBox(height: 150, child: LineChart(LineChartData(
          minY: (minY * 0.88).floorToDouble(),
          maxY: (maxY * 1.12).ceilToDouble(),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 48,
              getTitlesWidget: (v, _) => Text(
                '${(v / 1000).toStringAsFixed(1)}k',
                style: const TextStyle(
                    color: AppColors.textDim, fontSize: 10),
              ),
            )),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= preds.length) return const SizedBox();
                final d = DateTime.parse(preds[i].date);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat('dd\nEEE').format(d),
                    style: const TextStyle(
                        color: AppColors.textDim, fontSize: 9),
                    textAlign: TextAlign.center),
                );
              },
            )),
          ),
          lineBarsData: [LineChartBarData(
            spots: spots, isCurved: true, color: color, barWidth: 2.5,
            dotData: FlDotData(
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4, color: color,
                strokeWidth: 2,
                strokeColor: AppColors.surface,
              ),
            ),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(
              colors: [color.withOpacity(0.18), color.withOpacity(0)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            )),
          )],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItems: (s) => s.map((sp) => LineTooltipItem(
                '${NumberFormat('#,##0.0').format(sp.y)} L',
                TextStyle(color: color, fontWeight: FontWeight.bold),
              )).toList(),
            ),
          ),
        ))),

        const SizedBox(height: 15),

        // Data rows — same as "Current Stock / Capacity" footer in _buildTankCard
        ...preds.map((p) {
          final d = DateTime.parse(p.date);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Expanded(child: Text(
                DateFormat('EEE, d MMM').format(d),
                style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12, fontWeight: FontWeight.bold),
              )),
              Text(
                '${NumberFormat('#,##0.0').format(p.predictedLitres)} L',
                style: TextStyle(
                    color: color, fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SKELETON — uses your shimmer pattern
  // ══════════════════════════════════════════════════════════════════════════

  Widget _skeleton() => Shimmer.fromColors(
    baseColor: AppColors.surface,
    highlightColor: const Color(0xFF1E2820),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
      children: [
        _skelBox(56),  const SizedBox(height: 14),
        _skelBox(120), const SizedBox(height: 14),
        _skelBox(100), const SizedBox(height: 14),
        _skelBox(100), const SizedBox(height: 14),
        _skelBox(100), const SizedBox(height: 14),
        _skelBox(100),
      ],
    ),
  );

  Widget _skelBox(double h) => Container(
    height: h, width: double.infinity,
    margin: const EdgeInsets.only(bottom: 0),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  ERROR — same layout style as your empty state screens
  // ══════════════════════════════════════════════════════════════════════════

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: const Icon(Icons.wifi_off_rounded,
              color: AppColors.error, size: 36),
        ),
        const SizedBox(height: 20),
        const Text('Cannot reach prediction server',
            style: TextStyle(color: AppColors.textMain, fontSize: 18,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.1), width: 1.5),
          ),
          child: Text(_error ?? '',
              style: const TextStyle(
                  color: AppColors.textDim, fontSize: 11),
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 24),
        // Matches your FuelButton style
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            label: const Text('TRY AGAIN',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ]),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  DIALOGS — same style as your _confirmSave / _confirmDelete
  // ══════════════════════════════════════════════════════════════════════════

  void _retrainDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white10),
      ),
      title: const Row(children: [
        Icon(Icons.model_training_rounded, color: AppColors.primaryGreen),
        SizedBox(width: 10),
        Text('Retrain Models',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
      content: const Text(
        'Fetches the latest data from Firebase fuelSaleHistory and retrains '
        'all 4 prediction models.\n\n'
        'Runs in the background — takes 2–3 minutes.',
        style: TextStyle(color: AppColors.textDim, fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('CANCEL',
              style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              final msg = await _service.triggerRetrain();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: AppColors.secondaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed: $e'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: const Text('CONFIRM',
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  void _aboutDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white10),
      ),
      title: const Text('About',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('⛽ Emerald Lanka Fuel Prediction',
              style: TextStyle(color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 14),
          _aRow('Station',    'Emerald Lanka, Hettipola'),
          _aRow('Models',     '4 × XGBoost'),
          _aRow('Features',   '48 engineered features'),
          _aRow('Data up to', _data?.dataAsOf ?? '-'),
          _aRow('Petrol',     '±11.78% CV MAPE'),
          _aRow('Diesel',     '±17.39% CV MAPE'),
        ]),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('CLOSE',
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  // Matches your card decoration exactly
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.1), width: 1.5),
    ),
    child: child,
  );

  // Matches your section labels ("STATION OPERATIONS", "INVENTORY & LOGISTICS")
  Widget _sLabel(String t) => Text(t, style: const TextStyle(
    color: AppColors.primaryGreen, fontSize: 10,
    fontWeight: FontWeight.bold, letterSpacing: 1.5,
  ));

  Widget _pill(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withOpacity(0.3)),
    ),
    child: Text(t, style: TextStyle(
        color: c, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _badge(String mape, String rel) {
    final c = rel == 'high'
        ? AppColors.primaryGreen
        : rel == 'medium'
            ? AppColors.warning
            : AppColors.error;
    return _pill(mape, c);
  }

  Widget _guideRow(String label, String pct, Color c, String desc) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 110, child: Text(label,
              style: const TextStyle(
                  color: AppColors.textMain, fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(pct, style: TextStyle(
                color: c, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Text(desc, style: const TextStyle(
              color: AppColors.textDim, fontSize: 11)),
        ]),
      );

  Widget _aRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 90, child: Text(l,
          style: const TextStyle(
              color: AppColors.textDim, fontSize: 12))),
      Expanded(child: Text(v, style: const TextStyle(
          color: AppColors.textMain, fontSize: 12,
          fontWeight: FontWeight.w600))),
    ]),
  );
}