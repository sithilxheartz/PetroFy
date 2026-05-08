import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:petrofy/pages/admin/reorder_suggestions_page.dart';
import '../../services/fuel_service.dart';
import '../../models/fuel_tank_model.dart';
import '../../utils/app_colors.dart';

class ManagerFuelLevelDashboard extends StatefulWidget {
  const ManagerFuelLevelDashboard({super.key});

  @override
  State<ManagerFuelLevelDashboard> createState() => _FuelLevelDashboardState();
}

class _FuelLevelDashboardState extends State<ManagerFuelLevelDashboard>
    with TickerProviderStateMixin {
  final FuelService _fuelService = FuelService();
  String _selectedFilter = 'All';
  late AnimationController _waveController;
  late AnimationController _pulseController;

  final List<String> _fuelTypes = [
    'All',
    'Auto Diesel',
    'Super Diesel',
    '92 Petrol',
    '95 Petrol',
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  void _goToReorderPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReorderSuggestionsPage()),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStatusColor(double pct) {
    if (pct < 0.20) return AppColors.error;
    if (pct < 0.40) return AppColors.warning;
    return AppColors.primaryGreen;
  }

  String _getStatusLabel(double pct) {
    if (pct < 0.20) return "CRITICAL STOCK";
    if (pct < 0.40) return "LOW STOCK";
    return "OPTIMAL STOCK";
  }

  // Format liters cleanly — always show full number with comma separator
  String _formatLiters(double liters) {
    if (liters >= 1000) {
      // e.g. 25,227 L
      final formatted = liters
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
      return formatted;
    }
    return liters.toStringAsFixed(0);
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
          // ── AMBIENT GLOWS ──
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
                itemBuilder: (_, i) => _buildTankCard(tanks[i]),
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
                              count > 0
                                  ? "$count REORDER ALERT"
                                  : "WELL STOCKED",
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
    final double pct = (tank.currentQuantity / tank.capacity).clamp(0.0, 1.0);
    final double percentage = pct * 100;
    final Color statusColor = _getStatusColor(pct);
    final String statusLabel = _getStatusLabel(pct);
    final bool isCritical = pct < 0.20;

    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _pulseController]),
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withOpacity(
                isCritical ? 0.08 + (_pulseController.value * 0.18) : 0.1,
              ),
              width: 1.5,
            ),
            boxShadow: isCritical
                ? [
                    BoxShadow(
                      color: statusColor.withOpacity(
                        0.03 + _pulseController.value * 0.04,
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              // ── HEADER ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Type: ${tank.fuelType}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Price: Rs.${tank.fuelPrice}0",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── LIQUID TANK + STATS ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Liquid tank
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 180,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Background
                              Container(color: AppColors.background),

                              // Liquid fill
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                height: 180 * pct,
                                child: Stack(
                                  children: [
                                    Container(
                                      color: statusColor.withOpacity(0.15),
                                    ),
                                    // Wave
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      height: 20,
                                      child: CustomPaint(
                                        painter: _WavePainter(
                                          animValue: _waveController.value,
                                          color: statusColor.withOpacity(0.45),
                                        ),
                                      ),
                                    ),
                                    // Gloss
                                    Positioned(
                                      top: 18,
                                      left: 16,
                                      right: 16,
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              statusColor.withOpacity(0.25),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Grid lines
                              ...List.generate(3, (i) {
                                final y = 180.0 * (1 - (i + 1) / 4.0);
                                return Positioned(
                                  top: y,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.04),
                                  ),
                                );
                              }),

                              // Percentage center
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${percentage.toStringAsFixed(1)}%",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black54,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "REMAINING",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.35),
                                        fontSize: 7,
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Border
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    // Stats
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildStatBox(
                            "CURRENT QUNTITY",
                            "${_formatLiters(tank.currentQuantity)} L",
                            statusColor,
                          ),
                          const SizedBox(height: 8),
                          _buildStatBox(
                            "AVAILABLE SPACE",
                            "${_formatLiters(tank.capacity - tank.currentQuantity)} L",
                            AppColors.textDim,
                          ),
                          const SizedBox(height: 8),
                          _buildStatBox(
                            "TANK CAPACITY",
                            "${_formatLiters(tank.capacity)} L",
                            AppColors.textDim,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── PROGRESS BAR ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                colors: [
                                  statusColor.withOpacity(0.5),
                                  statusColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 20% marker
                        FractionallySizedBox(
                          widthFactor: 0.20,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 1.5,
                              height: 6,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "0 L",
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "▲ 20% MIN",
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "${_formatLiters(tank.capacity)} L",
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    final bool isDim = color == AppColors.textDim;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDim ? Colors.white.withOpacity(0.03) : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDim
              ? Colors.white.withOpacity(0.05)
              : color.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: isDim ? Colors.white60 : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
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

// ─────────────────────────────────────────
// WAVE PAINTER
// ─────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double animValue;
  final Color color;

  _WavePainter({required this.animValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y =
          sin((x / size.width * 2 * pi) + (animValue * 2 * pi)) * 5 +
          size.height * 0.5;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.animValue != animValue;
}
