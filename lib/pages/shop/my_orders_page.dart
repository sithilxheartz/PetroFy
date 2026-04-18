import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../utils/app_colors.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  // --- PDF GENERATION LOGIC ---
  Future<void> _generateReceipt(Map<String, dynamic> order) async {
    // 1. ALWAYS create a new document instance inside the function to prevent caching old data
    final pdf = pw.Document();

    final date = (order['createdAt'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final items = order['items'] as List<dynamic>;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "PETROFY STORE",
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                      pw.Text(
                        "This is a computer-generated document. No signature is required.",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "ID: ${order['orderId']}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        "$formattedDate",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 5),

              // SHIPPING INFO
              pw.Text(
                "SHIPPING DETAILS",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text("Customer: ${order['customerName']}"),
              pw.SizedBox(height: 1),
              pw.Text("Phone: ${order['phoneNumber']}"),
              pw.SizedBox(height: 1),
              pw.Text("Address: ${order['address']}"),
              pw.SizedBox(height: 20),

              // PRODUCT TABLE
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.green900,
                ),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                data: <List<String>>[
                  <String>['Product', 'Qty', 'Unit Price', 'Total'],
                  ...items.map(
                    (item) => [
                      item['name'].toString(),
                      item['quantity'].toString(),
                      "LKR ${item['price'].toInt()}",
                      "LKR ${(item['price'] * (item['quantity'] ?? 1)).toInt()}",
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    "Grand Total: LKR ${order['total'].toInt()}",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(thickness: 0.5),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "Thank you for choosing Petrofy Store!",
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    //   pw.Spacer(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // 2. Use a unique name for the job to force the OS to refresh the preview
    await Printing.layoutPdf(
      name: 'Receipt_${order['orderId']}',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "MY ORDERS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
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
          user == null
              ? const Center(child: Text("Please login to view orders"))
              : SafeArea(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('userId', isEqualTo: user.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error: ${snapshot.error}",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
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

                      final orders = snapshot.data!.docs;

                      if (orders.isEmpty) {
                        return const Center(
                          child: Text(
                            "No orders found",
                            style: TextStyle(color: AppColors.textDim),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          var order =
                              orders[index].data() as Map<String, dynamic>;
                          return _buildOrderCard(order);
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    DateTime date = (order['createdAt'] as Timestamp).toDate();
    String formattedDate = DateFormat('dd MMM, hh:mm a').format(date);
    List items = order['items'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['orderId'] ?? "ORD",
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              _statusChip(order['status'] ?? "Paid"),
            ],
          ),
          Text(
            formattedDate,
            style: const TextStyle(color: AppColors.textDim, fontSize: 11),
          ),
          const Divider(color: Colors.white10, height: 30),

          const Text(
            "ITEMS PURCHASED",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, i) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                  image: DecorationImage(
                    image: NetworkImage(items[i]['imageUrl'] ?? ""),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),

          _buildStepTracker(order['status'] ?? "Paid"),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${items.length} Products",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                "LKR ${order['total'].toInt()}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),

          // DOWNLOAD BUTTON
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _generateReceipt(order);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "DOWNLOAD ORDER RECEIPT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStepTracker(String currentStatus) {
    final List<String> steps = [
      "Paid",
      "Packed",
      "Handed Over",
      "Shipped",
      "Completed",
    ];
    int currentStep = steps.indexOf(currentStatus);

    return Row(
      children: List.generate(steps.length, (index) {
        bool isDone = index <= currentStep;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0
                          ? Colors.transparent
                          : (isDone ? AppColors.primaryGreen : Colors.white10),
                    ),
                  ),
                  Icon(
                    isDone ? Icons.check_circle : Icons.circle,
                    size: 12,
                    color: isDone ? AppColors.primaryGreen : Colors.white10,
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == steps.length - 1
                          ? Colors.transparent
                          : (index < currentStep
                                ? AppColors.primaryGreen
                                : Colors.white10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 7,
                  color: isDone ? Colors.white : Colors.white24,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
