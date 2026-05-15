// lib/screens/evaporation_screen.dart
// Evaporation dashboard — TOMORROW + HISTORY tabs
// Retrain button auto-stores all data to Firebase

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:petrofy/services/evaporation_service.dart';
import 'package:petrofy/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';


class EvaporationScreen extends StatefulWidget {
  const EvaporationScreen({super.key});

  @override
  State<EvaporationScreen> createState() => _EvaporationScreenState();
}

class _EvaporationScreenState extends State<EvaporationScreen>
    with SingleTickerProviderStateMixin {

  final _service = EvaporationService();
  late TabController _tabs;

  TomorrowEvapData? _tomorrow;
  EvapHistoryData?  _history;
  bool    _loading    = true;
  bool    _retraining = false;
  String? _error;

  static const _fuels = [
    {'key': 'petrol',       'label': '92 Petrol',   'icon': '🛢️', 'color': Color(0xFF40C4FF)},
    {'key': 'super_petrol', 'label': '95 Petrol',    'icon': '⚡',  'color': AppColors.primaryGreen},
    {'key': 'diesel',       'label': 'Auto Diesel',  'icon': '🚛',  'color': AppColors.warning},
    {'key': 'super_diesel', 'label': 'Super Diesel', 'icon': '💎',  'color': Color(0xFFCE93D8)},
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  // ── Load predictions + history ─────────────────────────────────────────────

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final tomorrow = await _service.getTomorrowEvaporation();
      final history  = await _service.getHistory(days: 60);
      setState(() {
        _tomorrow = tomorrow;
        _history  = history;
        _loading  = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Retrain — automatically stores ALL data to Firebase after training ─────

  Future<void> _retrain() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Row(children: [
          Icon(Icons.model_training_rounded,
              color: AppColors.primaryGreen),
          SizedBox(width: 10),
          Text('Retrain Models',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        content: const Text(
          'This will:\n\n'
          '1. Fetch latest weather data\n'
          '2. Retrain all 4 evaporation models\n'
          '3. Recalculate ALL historical evaporation\n'
          '4. Update Firebase with latest results\n\n'
          'Takes 3–5 minutes. If retrained twice, '
          'the second result overwrites the first.',
          style: TextStyle(
              color: AppColors.textDim, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _retraining = true);
    try {
      final msg = await _service.triggerRetrain();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.black),
            const SizedBox(width: 10),
            Expanded(child: Text(msg,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold))),
          ]),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _retraining = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ROOT BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: const Center(
                child: Text('💨', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('EVAPORATION LOSS', style: TextStyle(
              color: AppColors.primaryGreen, fontSize: 12,
              fontWeight: FontWeight.bold, letterSpacing: 1.5,
            )),
            const Text('Emerald Lanka, Hettipola',
                style: TextStyle(color: AppColors.textDim, fontSize: 11)),
          ]),
        ]),
        actions: [
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.primaryGreen),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
          ),
          // Retrain
          IconButton(
            icon: _retraining
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryGreen),
                  )
                : const Icon(Icons.model_training_rounded,
                    color: AppColors.primaryGreen),
            tooltip: 'Retrain models + update Firebase',
            onPressed: _retraining ? null : _retrain,
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
              fontWeight: FontWeight.bold, fontSize: 13,
              letterSpacing: 0.5),
          tabs: const [
            Tab(icon: Icon(Icons.today_rounded, size: 15),
                text: 'TOMORROW'),
            Tab(icon: Icon(Icons.history_rounded, size: 15),
                text: 'HISTORY'),
          ],
        ),
      ),

      body: Stack(children: [
        Positioned(top: -50, right: -50, child: Container(
          width: 250, height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.warning.withOpacity(0.04),
          ),
        )),
        Positioned(bottom: -50, left: -50, child: Container(
          width: 250, height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryGreen.withOpacity(0.03),
          ),
        )),
        SafeArea(
          child: _loading
              ? _skeleton()
              : _error != null
                  ? _errorView()
                  : TabBarView(
                      controller: _tabs,
                      children: [_tomorrowTab(), _historyTab()],
                    ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 1 — TOMORROW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _tomorrowTab() {
    final t      = _tomorrow!;
    final s      = t.summary;
    final fmt    = NumberFormat('#,##0.0');
    final fmtLkr = NumberFormat('#,##0');
    final dateStr = DateFormat('EEEE, d MMMM yyyy')
        .format(DateTime.parse(t.predictionFor));

    final weather  = t.petrol.weather;
    final tempMax  = (weather['temp_max_c'] as num?)?.toDouble();
    final rain     = (weather['precip_mm'] as num?)?.toDouble() ?? 0;
    final humidity = (weather['humidity_max'] as num?)?.toDouble();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryGreen,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 140),
        children: [

          // Date chip
          _card(child: Row(children: [
            const Icon(Icons.calendar_today_rounded,
                color: AppColors.primaryGreen, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(dateStr, style: const TextStyle(
                color: AppColors.textMain, fontSize: 14,
                fontWeight: FontWeight.w600))),
            if (tempMax != null) _weatherChip(tempMax, rain),
          ])),

          const SizedBox(height: 14),

          // Retrain info banner
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primaryGreen, size: 16),
              const SizedBox(width: 10),
              const Expanded(child: Text(
                'Tap the retrain icon (top right) to update models '
                'and recalculate all historical data in Firebase.',
                style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11, height: 1.4),
              )),
            ]),
          ),

          const SizedBox(height: 14),

          // Total evaporation banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: 26, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B4513),
                  AppColors.warning,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(
                color: AppColors.warning.withOpacity(0.3),
                blurRadius: 20, offset: const Offset(0, 6),
              )],
            ),
            child: Column(children: [
              Text('Total Predicted Evaporation Tomorrow',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('${fmt.format(s.totalEvapLitres)} L',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 42,
                      fontWeight: FontWeight.bold, letterSpacing: -1)),
              const SizedBox(height: 4),
              Text('LKR ${fmtLkr.format(s.totalEvapLkr)} lost',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),

          const SizedBox(height: 14),

          // Weather context
          if (tempMax != null)
            _card(child: Row(children: [
              _weatherInfo('🌡️', 'Max Temp',
                  '${tempMax.toStringAsFixed(1)}°C',
                  tempMax > 33 ? AppColors.error : AppColors.textDim),
              _divider(),
              _weatherInfo('💧', 'Humidity',
                  humidity != null
                      ? '${humidity.toStringAsFixed(0)}%'
                      : '-',
                  AppColors.textDim),
              _divider(),
              _weatherInfo('🌧️', 'Rain',
                  '${rain.toStringAsFixed(1)} mm',
                  rain > 5
                      ? const Color(0xFF40C4FF)
                      : AppColors.textDim),
            ])),

          const SizedBox(height: 14),

          // Annual estimate
          _card(child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                  child: Text('📊',
                      style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Annual Loss Estimate',
                    style: TextStyle(
                        color: AppColors.textDim, fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text('LKR ${fmtLkr.format(s.annualEstLkr)}',
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 24,
                        fontWeight: FontWeight.bold)),
                Text('~${fmt.format(s.annualEstLitres)} litres/year',
                    style: const TextStyle(
                        color: AppColors.textDim, fontSize: 12)),
              ],
            )),
          ])),

          const SizedBox(height: 18),
          _sLabel('FUEL BREAKDOWN'),
          const SizedBox(height: 12),

          // Per-fuel cards
          ..._fuels.map((f) {
            final key   = f['key'] as String;
            final color = f['color'] as Color;
            FuelEvap fuelData;
            switch (key) {
              case 'petrol':       fuelData = t.petrol;      break;
              case 'super_petrol': fuelData = t.superPetrol; break;
              case 'diesel':       fuelData = t.diesel;      break;
              default:             fuelData = t.superDiesel;
            }
            return _fuelEvapCard(
              icon:  f['icon']  as String,
              label: f['label'] as String,
              color: color,
              data:  fuelData,
            );
          }),

          // Accuracy guide
          _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sLabel('MODEL ACCURACY'),
              const SizedBox(height: 12),
              _accRow('🛢️ 92 Petrol',   '±3.3%',  const Color(0xFF40C4FF), 'Very accurate'),
              _accRow('🚛 Auto Diesel',  '±4.8%',  AppColors.warning,       'Very accurate'),
              _accRow('⚡ 95 Petrol',    '±13.2%', AppColors.warning,       'Good'),
              _accRow('💎 Super Diesel', '±30.9%', AppColors.error,         'Fair'),
              const SizedBox(height: 10),
              const Text(
                'XGBoost ML model trained on 384 days of data. '
                'Uses real weather: temperature, humidity, wind, ET0.',
                style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11, height: 1.5),
              ),
            ],
          )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 2 — HISTORY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _historyTab() {
    if (_history == null || _history!.records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_rounded,
                  color: AppColors.textDim, size: 60),
              const SizedBox(height: 20),
              const Text('No history yet',
                  style: TextStyle(color: AppColors.textMain,
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'Tap the retrain button to calculate and store '
                'all historical evaporation data.',
                style: TextStyle(color: AppColors.textDim, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retraining ? null : _retrain,
                icon: const Icon(Icons.model_training_rounded),
                label: const Text('RETRAIN NOW'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final records  = _history!.records;
    final fmt      = NumberFormat('#,##0');

    final spots = records.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.totalEvapL))
        .toList();
    final maxY = records.map((r) => r.totalEvapL)
        .reduce((a, b) => a > b ? a : b);
    final minY = records.map((r) => r.totalEvapL)
        .reduce((a, b) => a < b ? a : b);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryGreen,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 140),
        children: [

          // Stats row
          Row(children: [
            Expanded(child: _statBox(
              icon: '💧',
              label: '${records.length}-Day Total',
              value: '${_history!.periodTotalL.toStringAsFixed(1)} L',
              sub:   'LKR ${fmt.format(_history!.periodTotalLkr)}',
              color: AppColors.warning,
            )),
            const SizedBox(width: 12),
            Expanded(child: _statBox(
              icon: '📅',
              label: 'Annual Est.',
              value: 'LKR ${_formatLarge(_history!.annualEstLkr)}',
              sub:   'projected loss/year',
              color: AppColors.error,
            )),
          ]),

          const SizedBox(height: 14),

          // Chart
          _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sLabel('DAILY EVAPORATION — LAST ${records.length} DAYS'),
              const SizedBox(height: 4),
              const Text('Total litres lost per day',
                  style: TextStyle(
                      color: AppColors.textDim, fontSize: 12)),
              const SizedBox(height: 18),
              SizedBox(height: 180, child: LineChart(LineChartData(
                minY: (minY * 0.85).floorToDouble(),
                maxY: (maxY * 1.15).ceilToDouble(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 42,
                    getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}L',
                        style: const TextStyle(
                            color: AppColors.textDim, fontSize: 9)),
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= records.length) return const SizedBox();
                      if (i % 10 != 0) return const SizedBox();
                      final d = DateTime.parse(records[i].date);
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(DateFormat('d/M').format(d),
                            style: const TextStyle(
                                color: AppColors.textDim, fontSize: 9)),
                      );
                    },
                  )),
                ),
                lineBarsData: [LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.warning,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                    colors: [
                      AppColors.warning.withOpacity(0.2),
                      AppColors.warning.withOpacity(0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )),
                )],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    getTooltipItems: (s) => s.map((sp) {
                      final i = sp.x.toInt();
                      final r = i < records.length ? records[i] : null;
                      return LineTooltipItem(
                        '${sp.y.toStringAsFixed(3)} L\n'
                        '${r != null ? DateFormat("d MMM").format(DateTime.parse(r.date)) : ""}',
                        const TextStyle(color: AppColors.warning,
                            fontWeight: FontWeight.bold, fontSize: 11),
                      );
                    }).toList(),
                  ),
                ),
              ))),
            ],
          )),

          const SizedBox(height: 14),

          // Table
          _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sLabel('RECENT RECORDS'),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Text('Date',
                    style: TextStyle(color: AppColors.textDim,
                        fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 68, child: Text('Total L',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppColors.textDim,
                        fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 78, child: Text('LKR',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppColors.textDim,
                        fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 46, child: Text('Temp',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppColors.textDim,
                        fontSize: 11, fontWeight: FontWeight.bold))),
              ]),
              Divider(color: Colors.white.withOpacity(0.08), height: 16),
              ...records.reversed.take(20).map((r) {
                final d      = DateTime.parse(r.date);
                final isHot  = r.tempMaxC > 33;
                final isRain = r.precipMm > 5;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Expanded(child: Row(children: [
                      Text(DateFormat('EEE, d MMM').format(d),
                          style: const TextStyle(
                              color: AppColors.textDim, fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(isRain ? '🌧️' : isHot ? '☀️' : '',
                          style: const TextStyle(fontSize: 10)),
                    ])),
                    SizedBox(width: 68, child: Text(
                      r.totalEvapL.toStringAsFixed(3),
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AppColors.warning,
                          fontSize: 12, fontWeight: FontWeight.bold),
                    )),
                    SizedBox(width: 78, child: Text(
                      fmt.format(r.totalEvapLkr),
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AppColors.error,
                          fontSize: 12, fontWeight: FontWeight.bold),
                    )),
                    SizedBox(width: 46, child: Text(
                      '${r.tempMaxC.toStringAsFixed(0)}°C',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: isHot ? AppColors.warning : AppColors.textDim,
                          fontSize: 12),
                    )),
                  ]),
                );
              }),
            ],
          )),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _weatherChip(double temp, double rain) {
    final isRainy = rain > 5;
    final color   = isRainy ? const Color(0xFF40C4FF) : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(isRainy ? '🌧️' : '☀️',
            style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text('${temp.toStringAsFixed(0)}°C',
            style: TextStyle(color: color, fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _weatherInfo(String icon, String label, String value, Color c) =>
      Expanded(child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(
            color: AppColors.textDim, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
            color: c, fontSize: 13, fontWeight: FontWeight.bold)),
      ]));

  Widget _divider() => Container(
      width: 1, height: 40, color: Colors.white.withOpacity(0.08));

  Widget _fuelEvapCard({
    required String icon,
    required String label,
    required Color color,
    required FuelEvap data,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(icon,
                style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: Colors.white)),
              Text('Evaporation tomorrow',
                  style: const TextStyle(
                      color: AppColors.textDim, fontSize: 11)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${data.evapLitres.toStringAsFixed(4)} L',
                style: TextStyle(color: color, fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text('LKR ${data.evapLkr.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.textDim, fontSize: 12)),
            Text('${data.evapPctOfSales.toStringAsFixed(4)}% of sales',
                style: const TextStyle(
                    color: AppColors.textDim, fontSize: 11)),
          ]),
        ]),
      );

  Widget _accRow(String label, String pct, Color c, String desc) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 120, child: Text(label,
              style: const TextStyle(
                  color: AppColors.textMain, fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
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

  Widget _statBox({
    required String icon,
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                  color: AppColors.textDim, fontSize: 11,
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(
                  color: color, fontSize: 17,
                  fontWeight: FontWeight.bold)),
              Text(sub, style: const TextStyle(
                  color: AppColors.textDim, fontSize: 11)),
            ],
          )),
        ]),
      );

  Widget _skeleton() => Shimmer.fromColors(
    baseColor: AppColors.surface,
    highlightColor: const Color(0xFF1E2820),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
      children: [
        _skelBox(56), const SizedBox(height: 12),
        _skelBox(52), const SizedBox(height: 12),
        _skelBox(130), const SizedBox(height: 12),
        _skelBox(80), const SizedBox(height: 12),
        _skelBox(80), const SizedBox(height: 12),
        _skelBox(80), const SizedBox(height: 12),
        _skelBox(80),
      ],
    ),
  );

  Widget _skelBox(double h) => Container(
    height: h, width: double.infinity,
    decoration: BoxDecoration(color: AppColors.surface,
        borderRadius: BorderRadius.circular(24)),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.wifi_off_rounded,
              color: AppColors.error, size: 36),
        ),
        const SizedBox(height: 20),
        const Text('Cannot reach evaporation server',
            style: TextStyle(color: AppColors.textMain, fontSize: 18,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            label: const Text('TRY AGAIN',
                style: TextStyle(color: Colors.black,
                    fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.08), width: 1.5),
    ),
    child: child,
  );

  Widget _sLabel(String t) => Text(t, style: const TextStyle(
    color: AppColors.primaryGreen, fontSize: 10,
    fontWeight: FontWeight.bold, letterSpacing: 1.5,
  ));

  String _formatLarge(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}