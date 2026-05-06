import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/schedule_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class GenerateSchedulePage extends StatefulWidget {
  const GenerateSchedulePage({super.key});

  @override
  State<GenerateSchedulePage> createState() => _GenerateSchedulePageState();
}

class _GenerateSchedulePageState extends State<GenerateSchedulePage> {
  final ScheduleService _service = ScheduleService();

  DateTime _selectedWeekStart = _getNextMonday();
  bool _isLoading = false;

  // Result data after generation
  bool _hasResult = false;
  int _shiftsCreated = 0;
  List<dynamic> _unassignedSlots = [];
  String _weekOf = "";

  // Gets next Monday automatically
  static DateTime _getNextMonday() {
    DateTime now = DateTime.now();
    int daysUntilMonday = (8 - now.weekday) % 7;
    if (daysUntilMonday == 0) daysUntilMonday = 7;
    return DateTime(now.year, now.month, now.day + daysUntilMonday);
  }

  String _formatWeekRange(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    return "${DateFormat('dd MMM').format(monday)} — ${DateFormat('dd MMM yyyy').format(sunday)}";
  }

  void _pickWeek() async {
    // Let manager pick any Monday as the week start
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedWeekStart,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      helpText: "Pick the Monday to start the week",
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryGreen,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      // Snap to the Monday of the picked week
      final monday = picked.subtract(Duration(days: picked.weekday - 1));
      setState(() {
        _selectedWeekStart = monday;
        _hasResult = false; // reset result when week changes
      });
    }
  }

  void _generateSchedule() async {
    setState(() {
      _isLoading = true;
      _hasResult = false;
    });

    final result = await _service.generateSchedule(_selectedWeekStart);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _hasResult = true;
        _shiftsCreated = result['shiftsCreated'] ?? 0;
        _unassignedSlots = result['unassignedSlots'] ?? [];
        _weekOf = result['weekOf'] ?? '';
      });
    } else {
      showCustomSnackBar(
        context,
        result['message'] ?? 'Generation failed.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "GENERATE SCHEDULE",
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── INFO CARD ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "This will auto-assign all pumpers to shifts for the selected week based on their saved preferences.",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ── WEEK SELECTOR ──
                  _buildLabel("SELECT WEEK"),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _pickWeek,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
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
                                "WEEEK OF",
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                _formatWeekRange(_selectedWeekStart),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.calendar_month,
                            color: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Days of the week preview
                  Row(
                    children: List.generate(7, (i) {
                      final day = _selectedWeekStart.add(Duration(days: i));
                      final labels = [
                        "Mon",
                        "Tue",
                        "Wed",
                        "Thu",
                        "Fri",
                        "Sat",
                        "Sun",
                      ];
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                labels[i],
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${day.day}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // ── GENERATE BUTTON ──
                  FuelButton(
                    text: "GENERATE SCHEDULE",
                    isLoading: _isLoading,
                    onPressed: _generateSchedule,
                  ),

                  // ── RESULT SECTION ──
                  if (_hasResult) ...[
                    const SizedBox(height: 15),
                    _buildLabel("GENERATION RESULT"),
                    const SizedBox(height: 15),

                    // Success summary card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primaryGreen,
                            size: 36,
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Schedule Generated!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                "$_shiftsCreated shifts assigned for week of $_weekOf",
                                style: const TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Unassigned slots warning
                    if (_unassignedSlots.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${_unassignedSlots.length} slots could not be filled",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Not enough pumpers with matching availability. Please assign these manually in the Shift Roster:",
                              style: TextStyle(
                                color: AppColors.textDim,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // List unassigned slots
                            ..._unassignedSlots.map((slot) {
                              final s = Map<String, dynamic>.from(slot);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "${s['date']}  •  ${s['shift']}  •  ${s['pump']}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],

                    if (_unassignedSlots.isEmpty) ...[
                      const SizedBox(height: 15
                    ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: AppColors.primaryGreen,
                              size: 16,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "All pumps fully staffed for the week!",
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppColors.primaryGreen,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    ),
  );
}
