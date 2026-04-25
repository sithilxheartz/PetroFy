import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class ReportingHubPage extends StatelessWidget {
  final UserModel adminUser;
  const ReportingHubPage({super.key, required this.adminUser});

  // Generic navigator for development
  void _navigateToReport(BuildContext context, String title) {
    showCustomSnackBar(context, "$title module generating...");
    // You will replace these with actual report page routes later
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "STATION INSIGHTS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Glow effect matching your theme
          Positioned(top: -50, right: -50, child: _buildGlow()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                children: [
                  _buildMenuButton(
                    "Daily Sales Summary",
                    "Combined revenue from Fuel and Lubricants",
                    Icons.summarize_outlined,
                    () => _navigateToReport(context, "Daily Sales"),
                  ),
                  _buildMenuButton(
                    "Profit Margin Analysis",
                    "Buying vs Selling price profit breakdown",
                    Icons.trending_up_rounded,
                    () => _navigateToReport(context, "Profit Analysis"),
                  ),

                  const SizedBox(height: 5),

                  // --- FUEL & OPERATIONS ---
                  _buildSectionLabel("FUEL & OPERATIONS"),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    "Fuel Reconciliation",
                    "Dips vs Meter sales (Shortage/Loss report)",
                    Icons.ev_station_rounded,
                    () => _navigateToReport(context, "Fuel Reconciliation"),
                  ),
                  _buildMenuButton(
                    "Tank Evaporation Log",
                    "Monitoring fuel health and loss metrics",
                    Icons.opacity_rounded,
                    () => _navigateToReport(context, "Evaporation Log"),
                  ),

                  const SizedBox(height: 5),

                  // --- INVENTORY & RETAIL ---
                  _buildSectionLabel("INVENTORY & RETAIL"),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    "Stock Valuation",
                    "Total asset value of current lubricant stock",
                    Icons.inventory_2_outlined,
                    () => _navigateToReport(context, "Stock Valuation"),
                  ),
                  _buildMenuButton(
                    "Fast Moving Products",
                    "Identify highest selling lubricant brands",
                    Icons.auto_graph_rounded,
                    () => _navigateToReport(context, "Fast Moving Items"),
                  ),

                  const SizedBox(height: 5),

                  // --- STAFF & AUDIT ---
                  _buildSectionLabel("STAFF & SECURITY"),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    "Pumper Performance",
                    "Individual sales volume per staff member",
                    Icons.badge_outlined,
                    () => _navigateToReport(context, "Pumper Performance"),
                  ),
                  _buildMenuButton(
                    "Admin Audit Trail",
                    "Log of price changes and system modifications",
                    Icons.history_toggle_off_rounded,
                    () => _navigateToReport(context, "Audit Trail"),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS (THEME MATCHED) ---

  Widget _buildHeaderInfo() {
    return Column(
      children: [
        const Icon(
          Icons.analytics_outlined,
          color: AppColors.primaryGreen,
          size: 50,
        ),
        const SizedBox(height: 15),
        const Text(
          "System Intelligence",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Text(
          "Data driven insights for Petrofy AI",
          style: TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
