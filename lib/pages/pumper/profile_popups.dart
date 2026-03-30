import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fuel_sale_model.dart';
import '../../models/shift_model.dart';
import '../../services/sales_service.dart';
import '../../utils/app_colors.dart';

// --- SALES HISTORY POPUP ---
class SalesHistoryPopup extends StatefulWidget {
  final String pumperId;
  const SalesHistoryPopup({super.key, required this.pumperId});

  @override
  State<SalesHistoryPopup> createState() => _SalesHistoryPopupState();
}

class _SalesHistoryPopupState extends State<SalesHistoryPopup> {
  String _activeFilter = 'Today';

  DateTime _getStartDate() {
    DateTime now = DateTime.now();
    if (_activeFilter == '7 Days') return now.subtract(const Duration(days: 7));
    if (_activeFilter == '1 Month')
      return now.subtract(const Duration(days: 30));
    return DateTime(now.year, now.month, now.day); // Today 00:00:00
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

        // Calculate Totals for the Summary Card
        double totalVolume = sales.fold(
          0,
          (sum, item) => sum + item.soldQuantity,
        );
        double totalRevenue = sales.fold(
          0,
          (sum, item) => sum + item.soldTotalPrice,
        );

        return Column(
          children: [
            // 1. Filter Chips Row
            _buildFilterRow(),

            // 2. NEW: High-Impact Summary Card
            _buildSummaryCard(totalVolume, totalRevenue),

            const SizedBox(height: 10),

            // 3. Scrollable List
            Expanded(
              child: sales.isEmpty
                  ? const Center(
                      child: Text(
                        "No records for this period",
                        style: TextStyle(color: Colors.white24),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: sales.length,
                      itemBuilder: (context, index) =>
                          _buildSaleItem(sales[index]),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['Today', '7 Days', '1 Month'].map((filter) {
          bool isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryGreen,
              backgroundColor: AppColors.surface,
              onSelected: (val) => setState(() => _activeFilter = filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard(double volume, double revenue) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen.withOpacity(0.01), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem("TOTAL VOLUME", "${volume.toStringAsFixed(1)}L"),
          Container(width: 1, height: 40, color: Colors.white10),
          _buildSummaryItem(
            "TOTAL REVENUE",
            "LKR ${NumberFormat('#,###').format(revenue)}",
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSaleItem(FuelSaleModel sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sale.fuelType,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                DateFormat('dd MMM | hh:mm a').format(sale.dateTime),
                style: const TextStyle(color: AppColors.textDim, fontSize: 10),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "LKR ${sale.soldTotalPrice.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
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
}

// --- SHIFT HISTORY POPUP (Optimized) ---
class ShiftHistoryPopup extends StatelessWidget {
  final String pumperId;
  const ShiftHistoryPopup({super.key, required this.pumperId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShiftModel>>(
      stream: FirebaseFirestore.instance
          .collection('shiftSchedule')
          .where('pumperId', isEqualTo: pumperId)
          .orderBy('date', descending: true)
          .limit(20)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => ShiftModel.fromMap(d.data(), d.id))
                .toList(),
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        final shifts = snapshot.data ?? [];
        if (shifts.isEmpty)
          return const Center(
            child: Text(
              "No duty logs found",
              style: TextStyle(color: Colors.white24),
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: shifts.length,
          itemBuilder: (context, index) => _buildShiftItem(shifts[index]),
        );
      },
    );
  }

  Widget _buildShiftItem(ShiftModel shift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, dd MMM').format(shift.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  shift.shiftType.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            shift.pumpNumber,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
