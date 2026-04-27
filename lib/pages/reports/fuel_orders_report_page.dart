import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class FuelOrdersReportPage extends StatefulWidget {
  const FuelOrdersReportPage({super.key});

  @override
  State<FuelOrdersReportPage> createState() => _FuelOrdersReportPageState();
}

class _FuelOrdersReportPageState extends State<FuelOrdersReportPage> {
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  bool _isExporting = false;

  Future<Map<String, dynamic>> _fetchOrderReportData() async {
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
        .collection('fuelOrders')
        .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('orderDate', descending: true)
        .get();

    List<Map<String, dynamic>> orders = [];
    double totalVolume = 0;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      double qty = (data['quantity'] ?? 0).toDouble();
      totalVolume += qty;

      orders.add({
        'date': DateFormat(
          'dd MMM yyyy, hh:mm a',
        ).format((data['orderDate'] as Timestamp).toDate()),
        'fuelType': data['fuelType'] ?? "N/A",
        'qty': qty,
        'bowser': data['bowserNumber'] ?? "N/A",
        'receipt': data['receiptNumber'] ?? "N/A",
        'status': data['status'] ?? "pending",
        'admin': data['confirmedAdminName'] ?? "System", // <--- THE ADMIN NAME
      });
    }

    return {'orders': orders, 'totalVolume': totalVolume};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar:
          true, // Allows content to scroll under the blurred AppBar
      appBar: AppBar(
        title: const Text(
          "FUEL ORDER REPORT",
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
          _buildGlow(),
          SafeArea(
            child: Column(
              children: [
                _buildDateCard(),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _fetchOrderReportData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }
                      if (!snapshot.hasData ||
                          (snapshot.data!['orders'] as List).isEmpty) {
                        return const Center(
                          child: Text(
                            "No records found",
                            style: TextStyle(color: AppColors.textDim),
                          ),
                        );
                      }

                      final data = snapshot.data!;
                      final orders =
                          data['orders'] as List<Map<String, dynamic>>;

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: orders.length,
                              itemBuilder: (context, index) =>
                                  _buildProcurementCard(orders[index]),
                            ),
                          ),
                          _buildSummaryFooter(data),
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

  Widget _buildProcurementCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order['fuelType'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: order['status'] == 'pending'
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    order['status'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: order['status'] == 'pending'
                          ? Colors.orange
                          : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(
              children: [
                _rowInfo("Date", order['date']),
                _rowInfo(
                  "Confirmed By",
                  order['admin'],
                ), // <--- SHOWING ADMIN IN UI
                _rowInfo("Bowser", order['bowser']),
                _rowInfo("Receipt", order['receipt']),
                _rowInfo("Volume", "${order['qty']} L", isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 11),
          ),
          Text(
            val,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryFooter(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TOTAL REPLENISHMENT",
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${data['totalVolume']} Liters",
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          FuelButton(
            text: "DOWNLOAD REPORT",
            isLoading: _isExporting,
            onPressed: () => _generatePDF(data),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF(Map<String, dynamic> data) async {
    setState(() => _isExporting = true);
    final pdf = pw.Document();
    final orders = data['orders'] as List<Map<String, dynamic>>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "PETROFY - FUEL ORDER REPORT",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
                pw.Text(
                  "This is a computer-generated document. No signature is required.",
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 5),
              ],
            ),
          ),
          pw.Text(
            "Time Period: ${DateFormat('dd MMM yyyy').format(_selectedRange.start)} - ${DateFormat('dd MMM yyyy').format(_selectedRange.end)}",
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            data: <List<String>>[
              [
                'Date',
                'Fuel Type',
                'Bowser No',
                'Admin',
                'Qty (L)',
                'Status',
              ], // <--- ADDED ADMIN TO PDF TABLE
              ...orders.map(
                (o) => [
                  o['date'],
                  o['fuelType'],
                  o['bowser'],
                  o['admin'], // <--- VALUE FROM FIRESTORE
                  o['qty'].toString(),
                  o['status'],
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "TOTAL VOLUME RECEIVED: ${data['totalVolume']} L",
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green900,
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Fuel_Procurement_Report',
      onLayout: (format) async => pdf.save(),
    );
    setState(() => _isExporting = false);
  }

  Widget _buildDateCard() {
    return InkWell(
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
                  "SUPPLY PERIOD",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${DateFormat('dd MMM yyyy').format(_selectedRange.start)} - ${DateFormat('dd MMM yyyy').format(_selectedRange.end)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Icon(Icons.calendar_month, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }

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
