import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';

class StoreReportsPage extends StatefulWidget {
  const StoreReportsPage({super.key});

  @override
  State<StoreReportsPage> createState() => _StoreReportsPageState();
}

class _StoreReportsPageState extends State<StoreReportsPage> {
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // --- DATA PROCESSING LOGIC ---
  Future<Map<String, dynamic>> _fetchStoreReportData() async {
    DateTime start = DateTime(
      _selectedRange.start.year,
      _selectedRange.start.month,
      _selectedRange.start.day,
      0,
      0,
      0,
    );
    DateTime end = DateTime(
      _selectedRange.end.year,
      _selectedRange.end.month,
      _selectedRange.end.day,
      23,
      59,
      59,
    );

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .get();

    double totalRevenue = 0;
    List<Map<String, dynamic>> allOrders = [];
    Map<String, int> productSalesCount = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      allOrders.add(data);
      totalRevenue += (data['total'] ?? 0);

      List items = data['items'] ?? [];
      for (var item in items) {
        String name = item['name'] ?? "Unknown";
        productSalesCount[name] =
            (productSalesCount[name] ?? 0) + (item['quantity'] as int? ?? 1);
      }
    }

    // Filter by search query (Client-side for fast UX)
    List<Map<String, dynamic>> filteredOrders = allOrders.where((o) {
      String id = o['orderId'].toString().toLowerCase();
      String name = o['customerName'].toString().toLowerCase();
      return id.contains(_searchQuery.toLowerCase()) ||
          name.contains(_searchQuery.toLowerCase());
    }).toList();

    var sortedProducts = productSalesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'revenue': totalRevenue,
      'orderCount': allOrders.length,
      'filteredOrders': filteredOrders,
      'topSelling': sortedProducts.take(3).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "STORE ANALYTICS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildGlow(),
          SafeArea(
            child: Column(
              children: [
                _buildDateCard(),
                _buildSearchBar(), // NEW SEARCH BAR
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _fetchStoreReportData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }
                      final data = snapshot.data!;
                      final orders =
                          data['filteredOrders'] as List<Map<String, dynamic>>;

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildKPIOverview(
                            data['revenue'],
                            data['orderCount'],
                          ),
                          const SizedBox(height: 15),
                          _buildSectionLabel("COMPLETED ORDERS"),
                          const SizedBox(height: 15),
                          orders.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Text(
                                      "No matching orders",
                                      style: TextStyle(
                                        color: AppColors.textDim,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: orders
                                      .map((o) => _buildOrderTile(o))
                                      .toList(),
                                ),
                          const SizedBox(height: 100),
                        ],
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

  // --- NEW: SEARCH BAR COMPONENT ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15, top: 0),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search Order ID or Customer Name...",
          hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
          filled: true,
          fillColor: AppColors.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: AppColors.primaryGreen.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // --- UPDATED: ORDER TILE (CLICKABLE) ---
  Widget _buildOrderTile(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetails(order), // TRIGGER POP-UP
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['orderId'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    order['customerName'],
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "LKR ${order['total'].toInt()}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 3),
                  const Text(
                    "Tap for info",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW: ORDER DETAILS MODAL ---
  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ORDER SUMMARY",
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white30),
                  ),
                ],
              ),
              Text(
                order['orderId'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Placed on ${DateFormat('dd MMM yyyy, hh:mm a').format((order['createdAt'] as Timestamp).toDate())}",
                style: const TextStyle(color: AppColors.textDim, fontSize: 11),
              ),
              const Divider(color: Colors.white10, height: 20),

              const Text(
                "SHIPPING INFO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 10),
              _detailRow(Icons.person_outline, order['customerName']),
              _detailRow(Icons.phone_outlined, order['phoneNumber']),
              _detailRow(Icons.local_shipping_outlined, order['address']),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOTAL PAID",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "LKR ${order['total'].toInt()}",
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 5),
              const Text(
                "ITEMS PURCHASED",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.white38,
                ),
              ),
             // const SizedBox(height: 5),
              Expanded(
                child: ListView.builder(
                  itemCount: (order['items'] as List).length,
                  itemBuilder: (context, i) {
                    var item = order['items'][i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(item['imageUrl']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(
                        item['name'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text("Qty: ${item['quantity']}"),
                      trailing: Text(
                        "LKR ${(item['price'] * item['quantity']).toInt()}",
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ),
      ],
    ),
  );

  // --- REUSED HELPERS ---
  Widget _buildKPIOverview(double rev, int count) => Row(
    children: [
      _kpiCard(
        "TOTAL REVENUE",
        "LKR ${NumberFormat('#,###').format(rev)}",
        Icons.payments_outlined,
      ),
      const SizedBox(width: 15),
      _kpiCard("TOTAL ORDERS", "$count", Icons.shopping_bag_outlined),
    ],
  );
  Widget _kpiCard(String label, String value, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _buildDateCard() => InkWell(
    onTap: () async {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
      );
      if (picked != null) setState(() => _selectedRange = picked);
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "REPORTING PERIOD",
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "${DateFormat('dd MMM').format(_selectedRange.start)} - ${DateFormat('dd MMM yyyy').format(_selectedRange.end)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Icon(Icons.calendar_month, color: AppColors.primaryGreen),
        ],
      ),
    ),
  );
  Widget _buildSectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: AppColors.primaryGreen,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
    ),
  );
  Widget _buildGlow() => Positioned(
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
  );
}
