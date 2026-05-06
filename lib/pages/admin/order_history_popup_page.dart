import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/fuel_order_model.dart';
import '../../utils/app_colors.dart';

class OrderHistoryPopup extends StatefulWidget {
  const OrderHistoryPopup({super.key});

  @override
  State<OrderHistoryPopup> createState() => _OrderHistoryPopupState();
}

class _OrderHistoryPopupState extends State<OrderHistoryPopup> {
  String _activeFilter = '7 Days';

  final List<Map<String, dynamic>> _filters = [
    {'label': 'Today',   'icon': Icons.today_outlined},
    {'label': '7 Days',  'icon': Icons.date_range_outlined},
    {'label': '1 Month', 'icon': Icons.calendar_month_outlined},
    {'label': 'All',     'icon': Icons.all_inclusive},
  ];

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_activeFilter) {
      case 'Today':   return DateTime(now.year, now.month, now.day);
      case '1 Month': return now.subtract(const Duration(days: 30));
      case 'All':     return DateTime(2000);
      default:        return now.subtract(const Duration(days: 7));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fuelOrders')
          .where('orderDate',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(_getStartDate()))
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Query Error",
                style: TextStyle(color: AppColors.textDim)),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppColors.primaryGreen),
          );
        }

        final docs = snapshot.data!.docs;
        final orders = docs
            .map((d) => FuelOrderModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList();

        // Summary calculations
        final totalLiters =
            orders.fold(0.0, (sum, o) => sum + o.quantity);

        // Group by fuel type
        final Map<String, double> byFuel = {};
        for (final o in orders) {
          byFuel[o.fuelType] = (byFuel[o.fuelType] ?? 0) + o.quantity;
        }

        return Column(
          children: [
            // ── FILTER ROW ──
            _buildFilterRow(),

            // ── SUMMARY CARD ──
            if (orders.isNotEmpty)
              _buildSummaryCard(orders.length, totalLiters),

            // ── FUEL BREAKDOWN ──
            if (byFuel.isNotEmpty) _buildFuelBreakdown(byFuel),

            const SizedBox(height: 8),

            // ── LIST ──
            Expanded(
              child: orders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 40),
                      itemCount: orders.length,
                      itemBuilder: (_, i) =>
                          _buildOrderCard(orders[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ── FILTER ROW ──
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      child: Row(
        children: _filters.map((f) {
          final isSelected = _activeFilter == f['label'];
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _activeFilter = f['label']),
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
                    color: isSelected
                        ? AppColors.primaryGreen
                        : Colors.white10,
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

  // ── SUMMARY CARD ──
  Widget _buildSummaryCard(int count, double totalLiters) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primaryGreen.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            "DELIVERIES",
            "$count",
            Icons.local_shipping_outlined,
          ),
          Container(width: 1, height: 35, color: Colors.white10),
          _buildStat(
            "TOTAL INTAKE",
            "${NumberFormat('#,###').format(totalLiters)}L",
            Icons.water_drop_outlined,
          ),
          Container(width: 1, height: 35, color: Colors.white10),
          _buildStat(
            "AVG PER ORDER",
            "${NumberFormat('#,###').format(totalLiters / count)}L",
            Icons.analytics_outlined,
          ),
        ],
      ),
    );
  }

  // ── FUEL BREAKDOWN ──
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
            "INTAKE BY FUEL TYPE",
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
                      vertical: 8, horizontal: 4),
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
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${NumberFormat('#,###').format(e.value)}L",
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 12,
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

  // ── ORDER CARD ──
  Widget _buildOrderCard(FuelOrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: AppColors.primaryGreen.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Top row — fuel type + quantity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_gas_station_outlined,
                      color: AppColors.primaryGreen,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    order.fuelType,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Text(
                "${NumberFormat('#,###').format(order.quantity)} L",
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 10),

          // Bottom rows — details
          _buildDetailRow(
            Icons.calendar_today_outlined,
            "Date",
            DateFormat('dd MMM yyyy  •  hh:mm a')
                .format(order.orderDate),
          ),
          const SizedBox(height: 6),
          _buildDetailRow(
            Icons.receipt_outlined,
            "Invoice",
            order.receiptNumber,
          ),
          const SizedBox(height: 6),
          _buildDetailRow(
            Icons.local_shipping_outlined,
            "Bowser",
            order.bowserNumber,
          ),
          const SizedBox(height: 6),
          _buildDetailRow(
            Icons.person_outline,
            "Confirmed by",
            order.confirmedAdminName,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textDim),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: const TextStyle(
              color: AppColors.textDim, fontSize: 11),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 18),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 40, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 12),
          const Text(
            "No fuel orders for this period",
            style: TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
        ],
      ),
    );
  }
}