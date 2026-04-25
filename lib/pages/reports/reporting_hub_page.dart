import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class ReportingHubPage extends StatefulWidget {
  final UserModel adminUser;
  const ReportingHubPage({super.key, required this.adminUser});

  @override
  State<ReportingHubPage> createState() => _ReportingHubPageState();
}

class _ReportingHubPageState extends State<ReportingHubPage> {
  String _selectedFilter = "7D"; 

  final Map<String, int> _filterDays = {
    "7D": 7,
    "1M": 30,
    "6M": 180,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("STATION INSIGHTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
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
                children: [
                  _buildStackedBarSection(), // The new improved chart
                  const SizedBox(height: 25),
                  
                  _buildSectionLabel("FINANCIAL PERFORMANCE"),
                  const SizedBox(height: 15),
                  _buildMenuButton("Daily Sales Summary", "Combined revenue from Fuel and Lubricants", Icons.summarize_outlined, () {}),
                  _buildMenuButton("Profit Margin Analysis", "Buying vs Selling price profit breakdown", Icons.trending_up_rounded, () {}),

                  const SizedBox(height: 5),
                  _buildSectionLabel("FUEL & OPERATIONS"),
                  const SizedBox(height: 15),
                  _buildMenuButton("Fuel Reconciliation", "Dips vs Meter sales (Shortage/Loss report)", Icons.ev_station_rounded, () {}),
                  _buildMenuButton("Tank Evaporation Log", "Monitoring fuel health and loss metrics", Icons.opacity_rounded, () {}),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedBarSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sales Composition", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Daily Liters (Stacked by Type)", style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                ],
              ),
              _buildTimeFilter(),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<BarChartGroupData>>(
              future: _getStackedData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No records found", style: TextStyle(color: AppColors.textDim)));
                }
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _calculateMaxY(snapshot.data!),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.surface,
                        tooltipBorder: const BorderSide(color: Colors.white10),
                      ),
                    ),
                    titlesData: const FlTitlesData(show: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: snapshot.data!,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildLegend(),
        ],
      ),
    );
  }

  Future<List<BarChartGroupData>> _getStackedData() async {
    DateTime start = DateTime.now().subtract(Duration(days: _filterDays[_selectedFilter]!));
    
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection('fuelSales')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    Map<String, Map<String, double>> dailyData = {};

    for (var doc in snap.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String dateKey = DateFormat('yyyy-MM-dd').format((data['dateTime'] as Timestamp).toDate());
      String type = data['fuelType'] ?? "Other";
      double qty = (data['soldQuantity'] ?? 0).toDouble();

      dailyData.putIfAbsent(dateKey, () => {"95 Petrol": 0, "92 Petrol": 0, "Auto Diesel": 0, "Super Diesel": 0});
      if (dailyData[dateKey]!.containsKey(type)) {
        dailyData[dateKey]![type] = dailyData[dateKey]![type]! + qty;
      }
    }

    // Sort dates
    var sortedKeys = dailyData.keys.toList()..sort();
    
    return List.generate(sortedKeys.length, (index) {
      var fuels = dailyData[sortedKeys[index]]!;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: fuels["95 Petrol"]! + fuels["92 Petrol"]! + fuels["Auto Diesel"]! + fuels["Super Diesel"]!,
            width: _selectedFilter == "7D" ? 12 : 6,
            borderRadius: BorderRadius.circular(4),
            rodStackItems: [
              BarChartRodStackItem(0, fuels["95 Petrol"]!, AppColors.primaryGreen),
              BarChartRodStackItem(fuels["95 Petrol"]!, fuels["95 Petrol"]! + fuels["92 Petrol"]!, Colors.yellow),
              BarChartRodStackItem(fuels["95 Petrol"]! + fuels["92 Petrol"]!, fuels["95 Petrol"]! + fuels["92 Petrol"]! + fuels["Auto Diesel"]!, Colors.blue),
              BarChartRodStackItem(fuels["95 Petrol"]! + fuels["92 Petrol"]! + fuels["Auto Diesel"]!, fuels["95 Petrol"]! + fuels["92 Petrol"]! + fuels["Auto Diesel"]! + fuels["Super Diesel"]!, Colors.orange),
            ],
          ),
        ],
      );
    });
  }

  // --- UI HELPERS ---

  double _calculateMaxY(List<BarChartGroupData> groups) {
    double max = 0;
    for (var g in groups) {
      if (g.barRods[0].toY > max) max = g.barRods[0].toY;
    }
    return max == 0 ? 100 : max * 1.15;
  }

  Widget _buildTimeFilter() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: _filterDays.keys.map((key) {
          bool sel = _selectedFilter == key;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: sel ? AppColors.primaryGreen : Colors.transparent, borderRadius: BorderRadius.circular(10)),
              child: Text(key, style: TextStyle(color: sel ? Colors.black : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 15, runSpacing: 10,
      children: [
        _legItem("95 Petrol", AppColors.primaryGreen),
        _legItem("92 Petrol", Colors.yellow),
        _legItem("Auto Diesel", Colors.blue),
        _legItem("Super Diesel", Colors.orange),
      ],
    );
  }

  Widget _legItem(String t, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 5), Text(t, style: const TextStyle(color: AppColors.textDim, fontSize: 9))]);

  Widget _buildSectionLabel(String label) => Align(alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)));

  Widget _buildMenuButton(String title, String sub, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 22),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(sub, style: const TextStyle(color: AppColors.textDim, fontSize: 10))])),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlow() => Positioned(top: -50, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen.withOpacity(0.05))));
}