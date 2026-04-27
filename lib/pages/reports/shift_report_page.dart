import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/shift_model.dart';
import '../../services/shift_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class ShiftReportPage extends StatefulWidget {
  const ShiftReportPage({super.key});

  @override
  State<ShiftReportPage> createState() => _ShiftReportPageState();
}

class _ShiftReportPageState extends State<ShiftReportPage> {
  final ShiftService _shiftService = ShiftService();

  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  String? _selectedPumperId;
  String? _selectedPumperName;
  bool _isExporting = false;

  // --- DATA FETCHING ---
  Future<List<ShiftModel>> _fetchReportData() async {
    if (_selectedPumperId == null) return [];

    // Using your ShiftService logic
    return await _shiftService
        .getShiftsReport(
          pumperId: _selectedPumperId!,
          startDate: _selectedRange.start,
          endDate: _selectedRange.end,
        )
        .first; // Get current snapshot as a future
  }

  Widget _buildSummarySection(List<ShiftModel> shifts) {
    // 1. Calculate the counts
    int totalShifts = shifts.length;
    int dayShifts = shifts
        .where((s) => s.shiftType.toLowerCase().contains('day'))
        .length;
    int nightShifts = shifts
        .where((s) => s.shiftType.toLowerCase().contains('night'))
        .length;

    // 2. Calculate unique days worked
    int uniqueDays = shifts
        .map((s) => DateFormat('yyyy-MM-dd').format(s.date))
        .toSet()
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                "DAYS COUNT",
                uniqueDays.toString(),
                Icons.calendar_month_outlined,
              ),

              _buildSummaryItem(
                "DAY SHIFTS",
                dayShifts.toString(),
                Icons.wb_sunny_outlined,
              ),
              _buildSummaryItem(
                "NIGHT SHIFTS",
                nightShifts.toString(),
                Icons.nightlight_outlined,
              ),
              _buildSummaryItem(
                "TOTAL SHIFTS",
                totalShifts.toString(),
                Icons.assignment_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        //    Icon(icon, color: AppColors.primaryGreen, size: 16),
        //  const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "SHIFT ROSTER REPORT",
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
                _buildPumperSelectorCard(),
                _buildDateRangeCard(),
                Expanded(
                  child: FutureBuilder<List<ShiftModel>>(
                    future: _fetchReportData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }

                      final shifts = snapshot.data ?? [];

                      if (_selectedPumperId == null) {
                        return const Center(
                          child: Text(
                            "Select pumper to view data",
                            style: TextStyle(color: AppColors.textDim),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // --- NEW SUMMARY SECTION ---
                          if (shifts.isNotEmpty) _buildSummarySection(shifts),

                          Expanded(
                            child: shifts.isEmpty
                                ? const Center(
                                    child: Text(
                                      "No records found",
                                      style: TextStyle(
                                        color: AppColors.textDim,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    itemCount: shifts.length,
                                    itemBuilder: (context, index) =>
                                        _buildShiftRowCard(shifts[index]),
                                  ),
                          ),
                          if (shifts.isNotEmpty) _buildExportFooter(shifts),
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
  // --- UI COMPONENTS ---

  Widget _buildPumperSelectorCard() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'pumper')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 50);
          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPumperId,
              hint: const Text(
                "CHOOSE PUMPER",
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              isExpanded: true,
              dropdownColor: AppColors.surface,
              items: snapshot.data!.docs.map((p) {
                return DropdownMenuItem(
                  value: p.id,
                  child: Text("${p['firstName']} ${p['lastName']}"),
                  onTap: () => _selectedPumperName =
                      "${p['firstName']} ${p['lastName']}",
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPumperId = val),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _selectedRange = picked);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        padding: const EdgeInsets.all(15),
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
                  "ROSTER PERIOD",
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
            const Icon(
              Icons.calendar_today,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftRowCard(ShiftModel shift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, dd MMM').format(shift.date),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "${shift.shiftType} • Pump ${shift.pumpNumber}",
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
          ),
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primaryGreen,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildExportFooter(List<ShiftModel> shifts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: FuelButton(
        text: "GENERATE ROSTER PDF",
        isLoading: _isExporting,
        onPressed: () => _generateShiftPDF(shifts),
      ),
    );
  }

  // --- UPDATED PDF LOGIC TO INCLUDE SUMMARY ---
  Future<void> _generateShiftPDF(List<ShiftModel> shifts) async {
    setState(() => _isExporting = true);
    final pdf = pw.Document();

    int dayCount = shifts
        .where((s) => s.shiftType.toLowerCase().contains('day'))
        .length;
    int nightCount = shifts
        .where((s) => s.shiftType.toLowerCase().contains('night'))
        .length;

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
                  "PETROFY - SHIFT ROSTER REPORT",
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
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Pumper: $_selectedPumperName",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    "Period: ${DateFormat('dd MMM yyyy').format(_selectedRange.start)} - ${DateFormat('dd MMM yyyy').format(_selectedRange.end)}",
                  ),
                ],
              ),
              // Summary box in PDF
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      "Total Shifts: ${shifts.length} | Day Shifts: $dayCount | Night Shifts: $nightCount",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            data: <List<String>>[
              ['Date', 'Day', 'Shift Type', 'Pump No.', 'Pumper'],
              ...shifts.map(
                (s) => [
                  DateFormat('yyyy-MM-dd').format(s.date),
                  DateFormat('EEEE').format(s.date),
                  s.shiftType,
                  s.pumpNumber.toString(),
                  s.pumperName,
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Shift_Summary_Report',
      onLayout: (format) async => pdf.save(),
    );
    setState(() => _isExporting = false);
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
