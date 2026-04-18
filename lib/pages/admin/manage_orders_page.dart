import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  // 1. Search Query State
  String _searchQuery = "";

  static const Map<String, String> _statusLifecycle = {
    "Paid": "Packed",
    "Packed": "Handed Over",
    "Handed Over": "Shipped",
    "Shipped": "Completed",
  };

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order, String docId) {
    String currentStatus = order['status'] ?? "Paid";
    String? nextStatus = _statusLifecycle[currentStatus];
    List items = order['items'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
            //  mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ORDER DETAILS", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white38, size: 20)),
                  ],
                ),
               // const Divider(color: Colors.white10),
            //    const SizedBox(height: 5),
                Text(order['customerName']?.toUpperCase() ?? "GUEST", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Contact: ${order['phoneNumber'] ?? "N/A"}", style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
                const SizedBox(height: 25),
                _buildSectionLabel("DELIVERY ADDRESS"),
                Text(order['address'] ?? "No address", style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 14)),
                const SizedBox(height: 25),
                _buildSectionLabel("PACKING CHECKLIST"),
                ...items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background.withOpacity(0.5), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text("x${item['quantity']}", style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(child: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
                if (nextStatus != null)
                  FuelButton(
                    text: "UPDATE TO: $nextStatus",
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': nextStatus});
                      HapticFeedback.mediumImpact();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: AppColors.primaryGreen, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
  );

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10, top: 15),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search by Name or Order ID...",
          hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
          filled: true,
          fillColor: AppColors.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AppColors.primaryGreen.withOpacity(0.1), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("ACTIVE ORDERS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // --- THE GREEN THEME CIRCLE ---
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
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('status', isNotEqualTo: "Completed")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                      
                      // Local Filtering Logic
                      final filteredDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['customerName'] ?? "").toString().toLowerCase();
                        final id = (data['orderId'] ?? "").toString().toLowerCase();
                        return name.contains(_searchQuery) || id.contains(_searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return const Center(child: Text("No matching orders", style: TextStyle(color: AppColors.textDim)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var doc = filteredDocs[index];
                          var order = doc.data() as Map<String, dynamic>;
                          String status = order['status'] ?? "Paid";
                          List items = order['items'] ?? [];
                          
                          DateTime date = (order['createdAt'] as Timestamp).toDate();
                          String formattedDate = DateFormat('dd MMM, hh:mm a').format(date);

                          return GestureDetector(
                            onTap: () => _showOrderDetails(context, order, doc.id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(order['customerName'] ?? "Guest", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                                            const SizedBox(width: 8),
                                            _statusBadge(status),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "${order['orderId']} • ${items.length} items • $formattedDate",
                                          style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.primaryGreen.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
    ),
    child: Text(status.toUpperCase(), style: const TextStyle(color: AppColors.primaryGreen, fontSize: 8, fontWeight: FontWeight.bold)),
  );
}