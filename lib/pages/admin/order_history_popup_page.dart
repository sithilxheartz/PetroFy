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
  String _filter = '7 Days'; // Default filter

  // Helper to get the start date based on filter
  DateTime _getStartDate() {
    DateTime now = DateTime.now();
    switch (_filter) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case '7 Days':
        return now.subtract(const Duration(days: 7));
      case '1 Month':
        return DateTime(now.year, now.month - 1, now.day);
      default:
        return now;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // FILTER CHIPS
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['Today', '7 Days', '1 Month'].map((f) => _buildFilterChip(f)).toList(),
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('fuelOrders')
                .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(_getStartDate()))
                .orderBy('orderDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Query Error"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));

              final orders = snapshot.data!.docs;
              if (orders.isEmpty) return const Center(child: Text("No records found", style: TextStyle(color: AppColors.textDim)));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = FuelOrderModel.fromMap(orders[index].data() as Map<String, dynamic>, orders[index].id);
                  return _buildOrderCard(order);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _filter == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.black : Colors.white)),
        selected: isSelected,
        onSelected: (val) => setState(() => _filter = label),
        selectedColor: AppColors.primaryGreen,
        backgroundColor: AppColors.surface,
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildOrderCard(FuelOrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
    
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1), width: 1),
    
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.fuelType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${order.quantity.toStringAsFixed(0)} L", style: const TextStyle(color: AppColors.primaryGreen, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd MMM | hh:mm a').format(order.orderDate), style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              Text("Invoice: ${order.receiptNumber}", style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}