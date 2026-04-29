import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petrofy/pages/shop/fuel_dashboard.dart';
import 'package:petrofy/pages/reports/fuel_orders_report_page.dart';
import 'package:petrofy/pages/reports/fuel_sales_reports_page.dart';
import 'package:petrofy/pages/reports/store_report_page.dart';
import '../../utils/app_colors.dart';
import 'shift_report_page.dart';

class ReportingHubPage extends StatefulWidget {
  const ReportingHubPage({super.key});

  @override
  State<ReportingHubPage> createState() => _ReportingHubPageState();
}

class _ReportingHubPageState extends State<ReportingHubPage> {
  String _revenueFilter = "7D";
  final Map<String, int> _filterDays = {"7D": 7, "1M": 30, "6M": 180};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar:
          true, // Allows content to scroll under the blurred AppBar
      appBar: AppBar(
        title: const Text(
          "STATION INSIGHTS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
            fontSize: 21,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildGlow(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- DYNAMIC HEADER STATS ---
                  _buildHeaderStatsPanel(),
                  const SizedBox(height: 15),
                  _buildSectionLabel("OPERATIONAL INSIGHTS"),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    "Fuel Sales Report",
                    "Revenue breakdown, volume trends, and LKR performance",
                    Icons.bar_chart_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FuelReportsPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    "Fuel Order Report",
                    "Historical bowser deliveries and procurement costs",
                    Icons.local_shipping_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FuelOrdersReportPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    "Shift Roster Report",
                    "Shift attendance, pumper assignments, and active logs",
                    Icons.badge_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShiftReportPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    "Online Store Analytics",
                      "Revenue breakdown, volume trends, and LKR performance",
                    Icons.store_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StoreReportsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 5),
                  // --- INVENTORY & LOGISTICS ---
                  _buildSectionLabel("FUEL EVAPORAION ANALYSIS"),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    "Fuel Evaporation Analysis",
                    "AI-Powered fuel evaporation analysis model",
                    Icons.water_drop,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FuelLevelDashboard(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STATS PANEL WITH FILTER ---
  Widget _buildHeaderStatsPanel() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10, top: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Time Filter Segment
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _filterDays.keys.map((day) {
              bool isSelected = _revenueFilter == day;
              return GestureDetector(
                onTap: () => setState(() => _revenueFilter = day),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryGreen : Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                // Dynamic Revenue calculation
                Expanded(
                  child: FutureBuilder<double>(
                    future: _getRevenueForPeriod(_filterDays[_revenueFilter]!),
                    builder: (context, snapshot) {
                      String displayRev = snapshot.hasData
                          ? "LKR ${NumberFormat.compact().format(snapshot.data)}"
                          : "...";
                      return _HeaderStatItem(
                        "NET REVENUE",
                        displayRev,
                        Icons.payments_outlined,
                      );
                    },
                  ),
                ),
                Container(width: 1, height: 35, color: Colors.white10),
                // Active Shifts (Daily active pumpers)
                Expanded(
                  child: InkWell(
                    onTap: () => _showShiftInfo(),
                    child: FutureBuilder<int>(
                      future: _getActiveShiftCount(),
                      builder: (context, snapshot) {
                        String count = snapshot.hasData
                            ? snapshot.data.toString().padLeft(2, '0')
                            : "00";
                        return _HeaderStatItem(
                          "ACTIVE SHIFTS",
                          count,
                          Icons.timer_outlined,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC: DATABASE QUERIES ---
  Future<double> _getRevenueForPeriod(int days) async {
    DateTime start = DateTime.now().subtract(Duration(days: days));
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection('fuelSales')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    double total = 0;
    for (var doc in snap.docs) {
      total += (doc['soldTotalPrice'] ?? 0).toDouble();
    }
    return total;
  }

  Future<int> _getActiveShiftCount() async {
    // Counts unique pumpers who had a shift in the last 24 hours
    DateTime last24H = DateTime.now().subtract(const Duration(hours: 24));
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection('shiftSchedule')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(last24H))
        .get();

    var uniquePumpers = snap.docs.map((doc) => doc['pumperId']).toSet();
    return uniquePumpers.length;
  }

  void _showShiftInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "What are Active Shifts?",
          style: TextStyle(color: AppColors.primaryGreen, fontSize: 16),
        ),
        content: const Text(
          "This counts the number of pumpers currently assigned to nozzles and actively recording meter readings for the current cycle.",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Understand",
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 14),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    String title,
    String sub,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white12,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlow() => Positioned(
    top: -100,
    right: -100,
    child: Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen.withOpacity(0.05),
      ),
    ),
  );
}

class _HeaderStatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _HeaderStatItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
