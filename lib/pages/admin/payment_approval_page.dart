import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class PaymentApprovalPage extends StatefulWidget {
  final UserModel adminUser; // Logged-in admin passed from Admin Profile
  const PaymentApprovalPage({super.key, required this.adminUser});

  @override
  State<PaymentApprovalPage> createState() => _PaymentApprovalPageState();
}

class _PaymentApprovalPageState extends State<PaymentApprovalPage> {
  // Use 'late final' to prevent the Stream from recreating and causing buffer errors
  late final Stream<QuerySnapshot> _approvalStream;

  @override
  void initState() {
    super.initState();
    // Querying only pending or received payments
    _approvalStream = FirebaseFirestore.instance
        .collection('fuelSales')
        .where('status', whereIn: ['pending', 'payment received'])
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  // --- CORE LOGIC: Update Status with Admin ID and Name ---
  Future<void> _updatePaymentStatus(String docId, String nextStatus) async {
    try {
      await FirebaseFirestore.instance.collection('fuelSales').doc(docId).update({
        'status': nextStatus,
        'paymentReceiverId': widget.adminUser.uid, // Current Admin UID
        'paymentReceiverName':
            "${widget.adminUser.firstName} ${widget.adminUser.lastName}", // Current Admin Name
      });

      if (mounted) {
        showCustomSnackBar(context, "Transaction marked as $nextStatus");
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, "Update Failed: $e", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "PAYMENT VERIFICATION",
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
          // Subtle background glow
          Positioned(top: -50, right: -50, child: _buildGlow()),
          Positioned(bottom: -50, left: -50, child: _buildGlow()),

          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _approvalStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No pending payments found",
                      style: TextStyle(color: AppColors.textDim),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String id = docs[index].id;
                    final String status = data['status'] ?? 'pending';
                    final DateTime date = (data['dateTime'] as Timestamp)
                        .toDate();

                    return _buildApprovalCard(id, data, status, date);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(
    String id,
    Map<String, dynamic> data,
    String status,
    DateTime date,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
       //   color: _getStatusColor(status).withOpacity(0.1),
          color: AppColors.primaryGreen.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Top Row: Fuel and Revenue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['fuelType'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM | hh:mm a').format(date),
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                "LKR ${data['soldTotalPrice']}",
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Divider(color: Colors.white10, thickness: 1),
          ),

          // Middle Row: Pumper & Quantity Details
          Row(
            children: [
              _buildIconDetail(
                Icons.person_pin_rounded,
                data['pumperName'] ?? 'Unknown',
              ),
              const SizedBox(width: 25),
              _buildIconDetail(
                Icons.local_gas_station_rounded,
                "${data['soldQuantity']} L",
              ),
            ],
          ),

          const SizedBox(height: 5),

          // Bottom Row: Status Badge and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(status),
              Row(
                children: [
                  if (status == 'pending')
                    _actionButton(
                      "CASH RECEIVED",
                      AppColors.primaryGreen,
                      () => _updatePaymentStatus(id, 'payment received'),
                    ),
                  if (status == 'payment received')
                    _actionButton(
                      "ADDED TO SAFE",
                      Colors.white,
                      () => _updatePaymentStatus(id, 'added to safe'),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 14),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'pending') return Colors.red;
    if (status == 'payment received') return AppColors.primaryGreen;
    return AppColors.primaryGreen;
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
