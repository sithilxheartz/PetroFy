import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class FuelReportsPage extends StatefulWidget {
  const FuelReportsPage({super.key});

  @override
  State<FuelReportsPage> createState() => _FuelReportsPageState();
}

class _FuelReportsPageState extends State<FuelReportsPage> {
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  bool _isExporting = false;

  // --- DATA PROCESSING LOGIC ---
  Future<Map<String, dynamic>> _fetchAdvancedReportData() async {
    // Normalize range to cover full days
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
        .collection('fuelSales')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('dateTime', descending: true)
        .get();

    Map<String, Map<String, dynamic>> pumperMap = {};
    double grandTotalRevenue = 0;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String pName = data['pumperName'] ?? "Unknown";
      String fType = data['fuelType'] ?? "Unknown";
      // Using your exact Firestore field names:
      double qty = (data['soldQuantity'] ?? 0).toDouble();
      double price = (data['soldTotalPrice'] ?? 0).toDouble();
      DateTime saleDate = (data['dateTime'] as Timestamp).toDate();

      grandTotalRevenue += price;

      if (!pumperMap.containsKey(pName)) {
        pumperMap[pName] = {'totalRev': 0.0, 'transactions': []};
      }

      pumperMap[pName]!['totalRev'] += price;

      pumperMap[pName]!['transactions'].add({
        'date': DateFormat('dd MMM, hh:mm a').format(saleDate),
        'fuel': fType,
        'qty': qty,
        'rev': price,
      });
    }

    return {'pumperData': pumperMap, 'grandTotal': grandTotalRevenue};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar:
          true, // Allows content to scroll under the blurred AppBar
      appBar: AppBar(
        title: const Text(
          "FUEL SALES REPORT",
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
                    future: _fetchAdvancedReportData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }
                      if (!snapshot.hasData ||
                          (snapshot.data!['pumperData'] as Map).isEmpty) {
                        return const Center(
                          child: Text(
                            "No records found",
                            style: TextStyle(color: AppColors.textDim),
                          ),
                        );
                      }

                      final report = snapshot.data!;
                      final pumperData =
                          report['pumperData']
                              as Map<String, Map<String, dynamic>>;

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: pumperData.length,
                              itemBuilder: (context, index) {
                                String name = pumperData.keys.elementAt(index);
                                return _buildDetailedPumperCard(
                                  name,
                                  pumperData[name]!,
                                );
                              },
                            ),
                          ),
                          _buildGrandTotalFooter(report['grandTotal'], report),
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

  Widget _buildDetailedPumperCard(String name, Map<String, dynamic> data) {
    List txs = data['transactions'];
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
            padding: const EdgeInsets.all(15),
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "LKR ${NumberFormat('#,###').format(data['totalRev'])}",
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...txs
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          t['date'],
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          t['fuel'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${t['qty']}L",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        "LKR ${NumberFormat('#,###').format(t['rev'])}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildGrandTotalFooter(
    double grandTotal,
    Map<String, dynamic> fullData,
  ) {
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
                "GRAND TOTAL REVENUE",
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "LKR ${NumberFormat('#,###').format(grandTotal)}",
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
            onPressed: () => _generateDetailedPDF(fullData),
          ),
        ],
      ),
    );
  }

  Future<void> _generateDetailedPDF(Map<String, dynamic> report) async {
    setState(() => _isExporting = true);
    final pdf = pw.Document();
    final pumperData =
        report['pumperData'] as Map<String, Map<String, dynamic>>;

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
                  "PETROFY - FUEL SALES REPORT",
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
          ...pumperData.entries
              .map(
                (p) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      color: PdfColors.green900,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Pumper: ${p.key}",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            "Total: LKR ${NumberFormat('#,###').format(p.value['totalRev'])}",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.TableHelper.fromTextArray(
                      context: context,
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                      cellStyle: const pw.TextStyle(fontSize: 8),
                      data: <List<String>>[
                        ['Date/Time', 'Fuel Type', 'Quantity', 'Amount'],
                        ...(p.value['transactions'] as List).map(
                          (t) => [
                            t['date'],
                            t['fuel'],
                            "${t['qty']} L",
                            "LKR ${NumberFormat('#,###').format(t['rev'])}",
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                  ],
                ),
              )
              .toList(),
          //  pw.Divider(),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "NET REVENUE: LKR ${NumberFormat('#,###').format(report['grandTotal'])}",
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
      name: 'Fuel_Sales_Report',
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
                  "SOLD PERIOD",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
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
