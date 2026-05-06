import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fuel_sale_model.dart';
import '../../models/shift_model.dart';
import '../../services/sales_service.dart';
import '../../utils/app_colors.dart';

// ─────────────────────────────────────────
// SALES HISTORY POPUP
// ─────────────────────────────────────────
class SalesHistoryPopup extends StatefulWidget {
  final String pumperId;
  const SalesHistoryPopup({super.key, required this.pumperId});

  @override
  State<SalesHistoryPopup> createState() => _SalesHistoryPopupState();
}

class _SalesHistoryPopupState extends State<SalesHistoryPopup> {
  String _activeFilter = 'Today';

  final List<Map<String, dynamic>> _filters = [
    {'label': 'Today', 'icon': Icons.today_outlined},
    {'label': '7 Days', 'icon': Icons.date_range_outlined},
    {'label': '1 Month', 'icon': Icons.calendar_month_outlined},
    {'label': 'All', 'icon': Icons.all_inclusive},
  ];

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_activeFilter) {
      case '7 Days':
        return now.subtract(const Duration(days: 7));
      case '1 Month':
        return now.subtract(const Duration(days: 30));
      case 'All':
        return DateTime(2000);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FuelSaleModel>>(
      stream: SalesService().getPumperFilteredSales(
        widget.pumperId,
        _getStartDate(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        final sales = snapshot.data ?? [];
        final totalVolume = sales.fold(0.0, (s, i) => s + i.soldQuantity);
        final totalRevenue = sales.fold(0.0, (s, i) => s + i.soldTotalPrice);

        // Group by fuel type for breakdown
        final Map<String, double> byFuel = {};
        for (final s in sales) {
          byFuel[s.fuelType] = (byFuel[s.fuelType] ?? 0) + s.soldQuantity;
        }

        return Column(
          children: [
            // ── FILTER ROW ──
            _buildFilterRow(),

            // ── SUMMARY CARD ──
            _buildSummaryCard(totalVolume, totalRevenue, sales.length),

            // ── FUEL BREAKDOWN ──
            if (byFuel.isNotEmpty) _buildFuelBreakdown(byFuel),

            const SizedBox(height: 10),

            // ── LIST ──
            Expanded(
              child: sales.isEmpty
                  ? _buildEmptyState("No sales for this period")
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: sales.length,
                      itemBuilder: (_, i) => _buildSaleItem(sales[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
      child: Row(
        children: _filters.map((f) {
          final isSelected = _activeFilter == f['label'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = f['label']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGreen.withOpacity(0.15)
                      : AppColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : Colors.white10,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.textDim,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.textDim,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard(double volume, double revenue, int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat("TRANSACTIONS", "$count"),
          _buildDivider(),
          _buildStat("VOLUME", "${volume.toStringAsFixed(1)}L"),
          _buildDivider(),
          _buildStat("REVENUE", "LKR ${NumberFormat('#,###').format(revenue)}"),
        ],
      ),
    );
  }

  Widget _buildFuelBreakdown(Map<String, double> byFuel) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "FUEL BREAKDOWN",
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: byFuel.entries.map((e) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        e.key,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${e.value.toStringAsFixed(1)}L",
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleItem(FuelSaleModel sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          // Fuel type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_gas_station_outlined,
              color: AppColors.primaryGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.fuelType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy  •  hh:mm a').format(sale.dateTime),
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "LKR ${NumberFormat('#,###').format(sale.soldTotalPrice)}",
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                "${sale.soldQuantity}L",
                style: const TextStyle(color: AppColors.textDim, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() =>
      Container(width: 1, height: 30, color: Colors.white10);

  Widget _buildEmptyState(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inbox_outlined,
          size: 40,
          color: Colors.white.withOpacity(0.1),
        ),
        const SizedBox(height: 12),
        Text(
          msg,
          style: const TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────
// SHIFT HISTORY POPUP
// ─────────────────────────────────────────
class ShiftHistoryPopup extends StatefulWidget {
  final String pumperId;
  const ShiftHistoryPopup({super.key, required this.pumperId});

  @override
  State<ShiftHistoryPopup> createState() => _ShiftHistoryPopupState();
}

class _ShiftHistoryPopupState extends State<ShiftHistoryPopup> {
  String _activeFilter = 'This Week';

  final List<Map<String, dynamic>> _filters = [
    {'label': 'This Week', 'icon': Icons.view_week_outlined},
    {'label': '1 Month', 'icon': Icons.calendar_month_outlined},
    {'label': '3 Months', 'icon': Icons.date_range_outlined},
    {'label': 'All', 'icon': Icons.all_inclusive},
  ];

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_activeFilter) {
      case '1 Month':
        return now.subtract(const Duration(days: 30));
      case '3 Months':
        return now.subtract(const Duration(days: 90));
      case 'All':
        return DateTime(2000);
      default: // This Week — go back to Monday
        return now.subtract(Duration(days: now.weekday - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.utc(
      _getStartDate().year,
      _getStartDate().month,
      _getStartDate().day,
    );

    return StreamBuilder<List<ShiftModel>>(
      stream: FirebaseFirestore.instance
          .collection('shiftSchedule')
          .where('pumperId', isEqualTo: widget.pumperId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(
              DateTime.utc(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ), // ← add this
            ),
          )
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => ShiftModel.fromMap(d.data(), d.id))
                .toList(),
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        final shifts = snapshot.data ?? [];

        // Count day vs night
        final dayCount = shifts.where((s) => s.shiftType == "Day Shift").length;
        final nightCount = shifts
            .where((s) => s.shiftType == "Night Shift")
            .length;

        return Column(
          children: [
            // ── FILTER ROW ──
            _buildFilterRow(),

            // ── SUMMARY ──
            _buildShiftSummary(shifts.length, dayCount, nightCount),

            const SizedBox(height: 10),

            // ── LIST ──
            Expanded(
              child: shifts.isEmpty
                  ? _buildEmptyState("No duty logs for this period")
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 40),
                      itemCount: shifts.length,
                      itemBuilder: (_, i) => _buildShiftItem(shifts[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
      child: Row(
        children: _filters.map((f) {
          final isSelected = _activeFilter == f['label'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = f['label']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGreen.withOpacity(0.15)
                      : AppColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : Colors.white10,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.textDim,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.textDim,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShiftSummary(int total, int day, int night) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat("TOTAL", "$total", Icons.assignment_outlined),
          _buildDivider(),
          _buildStat(
            "DAY",
            "$day",
            Icons.wb_sunny_outlined,
            color: Colors.amber,
          ),
          _buildDivider(),
          _buildStat(
            "NIGHT",
            "$night",
            Icons.nights_stay_outlined,
            color: Colors.indigo[300]!,
          ),
          _buildDivider(),
          _buildStat("HOURS", "${total * 8}h", Icons.timer_outlined),
        ],
      ),
    );
  }

  Widget _buildShiftItem(ShiftModel shift) {
    final isDay = shift.shiftType == "Day Shift";
    final isUpcoming = shift.date.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isUpcoming
              ? AppColors.primaryGreen.withOpacity(0.2)
              : Colors.white.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          // Shift icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDay
                  ? Colors.amber.withOpacity(0.1)
                  : Colors.indigo.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDay ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
              color: isDay ? Colors.amber : Colors.indigo[300],
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(shift.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  shift.shiftType.toUpperCase(),
                  style: TextStyle(
                    color: isDay ? Colors.amber : Colors.indigo[300],
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  shift.pumpNumber.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              if (isUpcoming) ...[
                const SizedBox(height: 4),
                const Text(
                  "UPCOMING",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    String label,
    String value,
    IconData icon, {
    Color color = AppColors.primaryGreen,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() =>
      Container(width: 1, height: 35, color: Colors.white10);

  Widget _buildEmptyState(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inbox_outlined,
          size: 40,
          color: Colors.white.withOpacity(0.1),
        ),
        const SizedBox(height: 12),
        Text(
          msg,
          style: const TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
      ],
    ),
  );
}
