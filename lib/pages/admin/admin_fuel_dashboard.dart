import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:petrofy/pages/admin/reorder_suggestions_page.dart';
import '../../services/fuel_service.dart';
import '../../models/fuel_tank_model.dart';
import '../../utils/app_colors.dart';

class AdminFuelLevelDashboard extends StatefulWidget {
  const AdminFuelLevelDashboard({super.key});

  @override
  State<AdminFuelLevelDashboard> createState() => _FuelLevelDashboardState();
}

class _FuelLevelDashboardState extends State<AdminFuelLevelDashboard> {
  final FuelService _fuelService = FuelService();
  String _selectedFilter = 'All';
  final List<String> _fuelTypes = [
    'All',
    'Auto Diesel',
    'Super Diesel',
    '92 Petrol',
    '95 Petrol',
  ];

  void _goToReorderPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReorderSuggestionsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "FUEL INVENTORY",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
            fontSize: 21,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
        actions: [_buildFilterDropdown()],
      ),
      body: Stack(
        children: [
          // ── BACKGROUND GLOW ──
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withOpacity(0.05),
              ),
            ),
          ),

          // ── TANK LIST ──
          StreamBuilder<List<FuelTankModel>>(
            stream: _fuelService.getTanksByType(_selectedFilter),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                );
              }
              final tanks = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 140),
                itemCount: tanks.length,
                itemBuilder: (context, index) => _buildTankCard(tanks[index]),
              );
            },
          ),

          // ── REORDER BUTTON — always fixed at bottom right ──
          Positioned(
            // Distance from bottom — accounts for nav bar height
            top: 100,
            right: 20,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reorderSuggestions')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── MAIN BUTTON ──
                    GestureDetector(
                      onTap: _goToReorderPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: count > 0
                                ? AppColors.primaryGreen.withOpacity(0.2)
                                : AppColors.primaryGreen.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              count > 0
                                  ? Icons.auto_awesome_outlined
                                  : Icons.done_all_outlined,
                              color: count > 0
                                  ? AppColors.primaryGreen
                                  : AppColors.primaryGreen,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              count > 0 ? "$count REORDER ALERT" : "WELL STOCKED",
                              style: TextStyle(
                                color: count > 0 ? Colors.white : Colors.white,
                        fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── BADGE DOT ──
                    if (count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "$count",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTankCard(FuelTankModel tank) {
    double percentage = (tank.currentQuantity / tank.capacity) * 100;
    bool isLow = percentage < 20;
    Color statusColor = isLow
        ? const Color.fromARGB(202, 255, 82, 82)
        : const Color.fromARGB(180, 0, 255, 136);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Fuel Type: ${tank.fuelType}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            "Price: Rs.${tank.fuelPrice}0",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 15),

          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 25,
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      color: statusColor,
                      value: percentage,
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 70,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: statusColor.withOpacity(0.15),
                      value: 100 - percentage,
                      title: isLow
                          ? ''
                          : '${(100 - percentage).toStringAsFixed(1)}%',
                      radius: 70,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Stock: ${tank.currentQuantity} L",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Capacity: ${tank.capacity} L",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
              Icon(
                isLow
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: statusColor,
                size: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          dropdownColor: AppColors.surface,
          items: _fuelTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (val) => setState(() => _selectedFilter = val!),
        ),
      ),
    );
  }
}
