import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reorder_suggestion_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class ReorderSuggestionsPage extends StatelessWidget {
  const ReorderSuggestionsPage({super.key});

  Stream<List<ReorderSuggestionModel>> _getSuggestions() {
    return FirebaseFirestore.instance
        .collection('reorderSuggestions')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          print("📦 Found ${snap.docs.length} suggestions"); // debug
          return snap.docs
              .map((d) => ReorderSuggestionModel.fromMap(d.data(), d.id))
              .toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "REORDER SUGGESTIONS",
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
          Positioned(top: -50, right: -50, child: _buildGlow()),
          SafeArea(
            child: StreamBuilder<List<ReorderSuggestionModel>>(
              stream: _getSuggestions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  );
                }

                final suggestions = snapshot.data ?? [];

                if (suggestions.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  children: [
                    // Header info
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "${suggestions.length} fuel type${suggestions.length > 1 ? 's' : ''} need attention. Based on last 14 days average consumption. This will update everyday 8.00 AM",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    ...suggestions.map((s) => _buildSuggestionCard(context, s)),
      
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(BuildContext context, ReorderSuggestionModel s) {
    // Color urgency based on days left
    final Color urgencyColor = s.daysUntilThreshold <= 1
        ? Colors.red
        : s.daysUntilThreshold <= 2
        ? Colors.orange
        : Colors.amber;

    final String urgencyLabel = s.daysUntilThreshold <= 1
        ? "CRITICAL"
        : s.daysUntilThreshold <= 2
        ? "URGENT"
        : "SOON";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: urgencyColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // ── HEADER ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.local_gas_station_outlined,
                    color: urgencyColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.fuelType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "Hits 20% on ${DateFormat('EEEE, dd MMM').format(s.predictedDate)}",
                        style: TextStyle(color: urgencyColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: urgencyColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    urgencyLabel,
                    style: TextStyle(
                      color: urgencyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── STATS ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Tank level bar
                _buildLevelBar(s),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      Icons.water_drop_outlined,
                      "${s.currentPercent.toStringAsFixed(1)}%",
                      "CURRENT",
                      AppColors.primaryGreen,
                    ),
                    _buildStatDivider(),
                    _buildStat(
                      Icons.trending_down,
                      "${s.dailyAvgConsumption.toStringAsFixed(0)}L",
                      "PER DAY",
                      Colors.orange,
                    ),
                    _buildStatDivider(),
                    _buildStat(
                      Icons.schedule,
                      "${s.daysUntilThreshold.toStringAsFixed(1)}",
                      "DAYS LEFT",
                      urgencyColor,
                    ),
                    _buildStatDivider(),
                    _buildStat(
                      Icons.shopping_cart_outlined,
                      "${NumberFormat('#,###').format(s.suggestedOrderQty)}L",
                      "ORDER QTY",
                      Colors.blue,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Suggested order highlight
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primaryGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Order ${NumberFormat('#,###').format(s.suggestedOrderQty)}L to refill to 95% capacity",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () =>
                            _updateStatus(context, s.id, 'dismissed'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.2),
                            ),
                          ),
                        ),
                        child: const Text(
                          "DISMISS",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextButton(
                        onPressed: () =>
                            _updateStatus(context, s.id, 'ordered'),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen.withOpacity(
                            0.12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: AppColors.primaryGreen.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: const Text(
                          "MARK AS ORDERED ✓",
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
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
  }

  Widget _buildLevelBar(ReorderSuggestionModel s) {
    final double fillPercent = (s.currentQuantity / s.capacity).clamp(0.0, 1.0);
    final double thresholdPercent = (s.thresholdQty / s.capacity).clamp(
      0.0,
      1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${NumberFormat('#,###').format(s.currentQuantity.toInt())}L  /  ${NumberFormat('#,###').format(s.capacity.toInt())}L",
              style: const TextStyle(color: AppColors.textDim, fontSize: 10),
            ),
            Text(
              "20% = ${NumberFormat('#,###').format(s.thresholdQty.toInt())}L",
              style: const TextStyle(color: Colors.orange, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Background bar
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Fill bar
            FractionallySizedBox(
              widthFactor: fillPercent,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: fillPercent <= 0.20
                      ? Colors.red
                      : fillPercent <= 0.35
                      ? Colors.orange
                      : AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            // 20% threshold marker
            FractionallySizedBox(
              widthFactor: thresholdPercent,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(width: 2, height: 10, color: Colors.orange),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    String status,
  ) async {
    await FirebaseFirestore.instance
        .collection('reorderSuggestions')
        .doc(docId)
        .update({'status': status});

    if (context.mounted) {
      showCustomSnackBar(
        context,
        status == 'ordered' ? "Marked as ordered!" : "Suggestion dismissed.",
        isError: false,
      );
    }
  }

  Widget _buildStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
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

  Widget _buildStatDivider() =>
      Container(width: 1, height: 35, color: Colors.white10);

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 52,
          color: AppColors.primaryGreen.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        const Text(
          "All tanks are well stocked!",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "No reorder suggestions at this time.",
          style: TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildGlow() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen.withOpacity(0.05),
      ),
    );
  }
}
