import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
 Future<void> _generateReceipt(Map<String, dynamic> order) async {
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
              // --- PROFESSIONAL HEADER ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("PETROFY AI", 
                        style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                      pw.Text("Smart Lubricant Solutions", 
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    child: pw.Text("INVOICE", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // --- INVOICE INFO & CUSTOMER DETAILS ---
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("BILL TO:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(order['customerName']?.toUpperCase() ?? "CUSTOMER", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(order['address'] ?? ""),
                      pw.Text("Phone: ${order['phoneNumber']}"),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Order ID: ${order['orderId']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Date: $formattedDate"),
                      pw.Text("Status: ${order['status']}"),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // --- ITEMS TABLE ---
              pw.TableHelper.fromTextArray(
                border: null,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                context: context,
                data: <List<String>>[
                  <String>['Description', 'Qty', 'Unit Price', 'Total'],
                  ...items.map((item) => [
                        item['name'].toString(),
                        item['quantity'].toString(),
                        "LKR ${item['price'].toInt()}",
                        "LKR ${(item['price'] * (item['quantity'] ?? 1)).toInt()}"
                      ])
                ],
              ),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              
              // --- TOTALS SECTION ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Subtotal:", style: const pw.TextStyle(fontSize: 10)),
                            pw.Text("LKR ${order['total'].toInt()}", style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Tax (0%):", style: const pw.TextStyle(fontSize: 10)),
                            pw.Text("LKR 0", style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Divider(color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Grand Total:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.Text("LKR ${order['total'].toInt()}", 
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // --- FOOTER & DISCLAIMER ---
              pw.Spacer(),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("This is a computer-generated document. No signature is required.", 
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.SizedBox(height: 5),
                    pw.Text("Thank you for choosing Petrofy AI - Your partner in automotive excellence.", 
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
