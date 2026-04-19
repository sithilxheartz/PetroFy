// lib/screens/dashboard_screen.dart
// Main fuel prediction dashboard with 2 tabs:
//   Tab 1 — Tomorrow's predictions (cards)
//   Tab 2 — 7-day forecast (line charts)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../models/prediction_model.dart';
import '../services/prediction_service.dart';

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

  // ── Colours ───────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF0F172A);   // dark navy
  static const _surface = Color(0xFF1E293B);   // card surface
  static const _accent  = Color(0xFF10B981);   // emerald green
  static const _text    = Colors.white;
  static const _textDim = Color(0xFF94A3B8);

  static Color fuelColor(String key) {
    final c = FuelMeta.fuels.firstWhere((f) => f['key'] == key, orElse: () => FuelMeta.fuels[0]);
    return Color(c['color'] as int);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
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
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getSummary();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _loading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabs,
                  children: [_buildTomorrowTab(), _buildSevenDayTab()],
                ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('⛽', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('EMERALD LANKA',
                  style: TextStyle(
                    color: _accent, fontSize: 13,
                    fontWeight: FontWeight.bold, letterSpacing: 1.5,
                  )),
              Text('Hettipola Filling Station',
                  style: TextStyle(color: _textDim, fontSize: 11)),
            ],
          ),
        ],
      ),
      actions: [
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _accent),
          onPressed: _loading ? null : _load,
          tooltip: 'Refresh',
        ),
        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: _textDim),
          color: _surface,
          onSelected: (v) {
            if (v == 'retrain') _showRetrainDialog();
            if (v == 'about')   _showAboutDialog();
          },
          itemBuilder: (_) => [
            _menuItem('retrain', Icons.model_training, 'Retrain Models'),
            _menuItem('about',   Icons.info_outline,   'About'),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabs,
        indicatorColor: _accent,
        indicatorWeight: 3,
        labelColor: _accent,
        unselectedLabelColor: _textDim,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: '📅  TOMORROW'),
          Tab(text: '📈  7 DAYS'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String v, IconData icon, String label) {
    return PopupMenuItem(
      value: v,
      child: Row(children: [
        Icon(icon, color: _accent, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: _text)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 1 — TOMORROW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTomorrowTab() {
    final t = _data!.tomorrow;
    final dateStr = DateFormat('EEEE, d MMMM yyyy')
        .format(DateTime.parse(t.petrol.date));

    final fuels = [
      ('petrol',       t.petrol,      'Petrol'),
      ('super_petrol', t.superPetrol, 'Super Petrol'),
      ('diesel',       t.diesel,      'Diesel'),
      ('super_diesel', t.superDiesel, 'Super Diesel'),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      color: _accent,
      backgroundColor: _surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Date header ───────────────────────────────────────────────
            _card(
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, color: _accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(dateStr,
                    style: const TextStyle(color: _text, fontSize: 15,
                        fontWeight: FontWeight.w600)),
                ),
                // Data freshness badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Updated ${_data!.dataAsOf}',
                    style: TextStyle(color: _accent, fontSize: 10),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 12),

            // ── Total banner ──────────────────────────────────────────────
            _totalBanner(t.totalLitres),

            const SizedBox(height: 12),

            // ── Individual fuel cards ─────────────────────────────────────
            ...fuels.map((f) {
              final key   = f.$1;
              final pred  = f.$2;
              final label = f.$3;
              final color = fuelColor(key);
              final note  = _data!.accuracyNotes[key];
              return _fuelCard(
                key: key, label: label,
                litres: pred.predictedLitres,
                color: color, note: note,
              );
            }),

            const SizedBox(height: 8),

            // ── Accuracy disclaimer ───────────────────────────────────────
            _accuracyDisclaimer(),

          ],
        ),
      ),
    );
  }

  Widget _totalBanner(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _accent.withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Text('Total Predicted Sales Tomorrow',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
        const SizedBox(height: 8),
        Text(
          '${NumberFormat('#,##0.0').format(total)} L',
          style: const TextStyle(color: Colors.white, fontSize: 38,
              fontWeight: FontWeight.bold),
        ),
      ]),
    );
  }

  Widget _fuelCard({
    required String key,
    required String label,
    required double litres,
    required Color color,
    AccuracyNote? note,
  }) {
    final emoji = FuelMeta.fuels
        .firstWhere((f) => f['key'] == key)['emoji'] as String;
    final isLowAccuracy = note?.reliability == 'low';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Icon circle
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(color: _textDim, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      '${NumberFormat('#,##0.0').format(litres)} L',
                      style: TextStyle(color: color, fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Accuracy badge
              if (note != null)
                _accuracyBadge(note.reliability, note.mapePct),
            ]),

            // Low accuracy warning
            if (isLowAccuracy) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(note!.note,
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 11)),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accuracyBadge(String reliability, double mape) {
    Color badgeColor;
    String badgeLabel;
    switch (reliability) {
      case 'high':
        badgeColor = _accent; badgeLabel = '±${mape.toStringAsFixed(0)}%';
        break;
      case 'medium':
        badgeColor = Colors.amber; badgeLabel = '±${mape.toStringAsFixed(0)}%';
        break;
      default:
        badgeColor = Colors.orange; badgeLabel = '±${mape.toStringAsFixed(0)}%';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Text(badgeLabel,
          style: TextStyle(color: badgeColor,
              fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _accuracyDisclaimer() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.info_outline, color: _textDim, size: 16),
            SizedBox(width: 8),
            Text('Accuracy Guide',
                style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          _infoRow('⛽ Petrol',       '±7%',  _accent,       'Very reliable'),
          _infoRow('🚛 Diesel',       '±14%', Colors.amber,  'Good for planning'),
          _infoRow('🔋 Super Petrol', '±50%', Colors.orange, 'Rough estimate'),
          _infoRow('💎 Super Diesel', '±63%', Colors.orange, 'Rough estimate'),
          const SizedBox(height: 8),
          Text(
            'Low accuracy for super fuels is due to out-of-stock days in training data. '
            'Accuracy improves as you add more monthly data.',
            style: TextStyle(color: _textDim, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String pct, Color color, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 100,
            child: Text(label, style: const TextStyle(color: _text, fontSize: 12))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(pct, style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.bold)),
        ),
        Text(desc, style: const TextStyle(color: _textDim, fontSize: 11)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 2 — 7 DAYS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSevenDayTab() {
    final sd = _data!.sevenDays;
    final fuelData = [
      ('petrol',       sd.petrol,      'Petrol'),
      ('diesel',       sd.diesel,      'Diesel'),
      ('super_petrol', sd.superPetrol, 'Super Petrol'),
      ('super_diesel', sd.superDiesel, 'Super Diesel'),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      color: _accent,
      backgroundColor: _surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Combined all-fuels overview chart
            _combinedOverviewChart(sd),
            const SizedBox(height: 16),
            // Individual fuel charts
            ...fuelData.map((f) => _sevenDayFuelChart(f.$1, f.$2, f.$3)),
          ],
        ),
      ),
    );
  }

  Widget _combinedOverviewChart(SevenDayData sd) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7-Day Total Overview',
              style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text('All fuel types combined', style: TextStyle(color: _textDim, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (v, _) => Text(
                        '${(v / 1000).toStringAsFixed(1)}k',
                        style: const TextStyle(color: _textDim, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= sd.petrol.length) return const SizedBox();
                        final d = DateTime.parse(sd.petrol[i].date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(DateFormat('dd\nEEE').format(d),
                            style: const TextStyle(color: _textDim, fontSize: 9),
                            textAlign: TextAlign.center),
                        );
                      },
                    ),
                  ),
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
                        colors: [Color(0xFF065F46), Color(0xFF10B981)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 28,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ]);
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _surface,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${NumberFormat('#,##0').format(rod.toY)} L',
                      const TextStyle(color: _accent, fontWeight: FontWeight.bold),
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

  Widget _sevenDayFuelChart(
      String key, List<FuelPrediction> preds, String label) {
    final color = fuelColor(key);
    final emoji = FuelMeta.fuels.firstWhere((f) => f['key'] == key)['emoji'] as String;
    final spots = preds.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.predictedLitres))
        .toList();
    final maxY = preds.map((p) => p.predictedLitres).reduce((a, b) => a > b ? a : b);
    final minY = preds.map((p) => p.predictedLitres).reduce((a, b) => a < b ? a : b);
    final note = _data!.accuracyNotes[key];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const Spacer(),
              if (note != null) _accuracyBadge(note.reliability, note.mapePct),
            ]),
            const SizedBox(height: 16),

            // Line chart
            SizedBox(
              height: 150,
              child: LineChart(LineChartData(
                minY: (minY * 0.9).floorToDouble(),
                maxY: (maxY * 1.1).ceilToDouble(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 48,
                      getTitlesWidget: (v, _) => Text(
                        '${(v / 1000).toStringAsFixed(1)}k',
                        style: const TextStyle(color: _textDim, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= preds.length) return const SizedBox();
                        final d = DateTime.parse(preds[i].date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(DateFormat('dd\nEEE').format(d),
                            style: const TextStyle(color: _textDim, fontSize: 9),
                            textAlign: TextAlign.center),
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
                        strokeColor: _surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.2), color.withOpacity(0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => _bg,
                    getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                      '${NumberFormat('#,##0.0').format(s.y)} L',
                      TextStyle(color: color, fontWeight: FontWeight.bold),
                    )).toList(),
                  ),
                ),
              )),
            ),

            const SizedBox(height: 12),

            // Data table
            ...preds.map((p) {
              final d = DateTime.parse(p.date);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Expanded(
                    child: Text(DateFormat('EEE, d MMM').format(d),
                        style: const TextStyle(color: _textDim, fontSize: 12)),
                  ),
                  Text(
                    '${NumberFormat('#,##0.0').format(p.predictedLitres)} L',
                    style: TextStyle(color: color, fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOADING SKELETON
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: _surface,
      highlightColor: const Color(0xFF334155),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _skeletonBox(height: 56),
          const SizedBox(height: 12),
          _skeletonBox(height: 100),
          const SizedBox(height: 12),
          _skeletonBox(height: 80),
          const SizedBox(height: 12),
          _skeletonBox(height: 80),
          const SizedBox(height: 12),
          _skeletonBox(height: 80),
          const SizedBox(height: 12),
          _skeletonBox(height: 80),
        ]),
      ),
    );
  }

  Widget _skeletonBox({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ERROR STATE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Colors.red, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Cannot reach prediction server',
                style: TextStyle(color: _text, fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              _error ?? '',
              style: const TextStyle(color: _textDim, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '💡 Make sure your Python API is running:\n'
                'uvicorn api.main:app --reload --port 8000\n\n'
                'Android emulator: use http://10.0.2.2:8000\n'
                'Physical device: use your PC\'s local IP',
                style: TextStyle(color: _textDim, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DIALOGS
  // ══════════════════════════════════════════════════════════════════════════

  void _showRetrainDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.model_training, color: _accent),
          SizedBox(width: 10),
          Text('Retrain Models', style: TextStyle(color: _text)),
        ]),
        content: const Text(
          'This will fetch the latest sales data from Firebase and retrain '
          'all 4 prediction models.\n\nThe process runs in the background '
          'and takes 2–3 minutes. Predictions will automatically update when done.',
          style: TextStyle(color: _textDim, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final msg = await _service.triggerRetrain();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(msg),
                    backgroundColor: _accent,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Retrain failed: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: const Text('Start Retraining'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About', style: TextStyle(color: _text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⛽ Emerald Lanka Fuel Prediction',
                style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _aboutRow('Station', 'Emerald Lanka Filling Station'),
            _aboutRow('Location', 'Hettipola, Kurunegala'),
            _aboutRow('Models', '4 XGBoost models'),
            _aboutRow('Features', '48 engineered features'),
            _aboutRow('Training data', '${_data?.dataAsOf ?? "-"} (latest)'),
            _aboutRow('Petrol accuracy', '±7.21%'),
            _aboutRow('Diesel accuracy', '±13.62%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120,
              child: Text(label, style: const TextStyle(color: _textDim, fontSize: 13))),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: _text, fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Shared card wrapper ───────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}