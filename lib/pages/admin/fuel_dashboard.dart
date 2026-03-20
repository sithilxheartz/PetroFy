import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/fuel_service.dart';
import '../../models/fuel_tank_model.dart';
import '../../utils/app_colors.dart';

class FuelLevelDashboard extends StatefulWidget {
  const FuelLevelDashboard({super.key});

  @override
  State<FuelLevelDashboard> createState() => _FuelLevelDashboardState();
}

class _FuelLevelDashboardState extends State<FuelLevelDashboard> {
  final FuelService _fuelService = FuelService();
  String _selectedFilter = 'All';
  final List<String> _fuelTypes = ['All', 'Auto Diesel', 'Super Diesel', '92 Petrol', '95 Petrol'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true, // Allows content to scroll under the blurred AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Frost effect
            child: AppBar(
              title: const Text(
                "SYSTEM INVENTORY",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18),
              ),
              backgroundColor: AppColors.background.withOpacity(0.5),
              elevation: 0,
              actions: [_buildFilterDropdown()],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Glow Decoration
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withOpacity(0.05),
              ),
            ),
          ),
          StreamBuilder<List<FuelTankModel>>(
            stream: _fuelService.getTanksByType(_selectedFilter),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
              
              final tanks = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20), // Top padding for transparent AppBar
                itemCount: tanks.length,
                itemBuilder: (context, index) => _buildTankCard(tanks[index]),
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildTankCard(FuelTankModel tank) {
    double percentage = (tank.currentQuantity / tank.capacity) * 100;
    bool isLow = percentage < 25; // Alert if below 20%
    Color statusColor = isLow ? AppColors.error : AppColors.primaryGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),

          // Chart Section
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                children: [
                  PieChart(
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
                          titleStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Centered Hole Decoration
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Data Footer
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "Capacity: ${tank.capacity} L",
                    style: const TextStyle(
                      fontSize: 12,
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
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
