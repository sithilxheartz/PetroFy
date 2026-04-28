import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petrofy/pages/pumper/preferences_page.dart';
import 'package:petrofy/pages/pumper/request_swap_page.dart';
import 'package:petrofy/pages/pumper/swap_requests_page.dart';
import '../../models/shift_model.dart';
import '../../models/user_model.dart';
import '../../services/shift_service.dart';
import '../../utils/app_colors.dart';

class MySchedulePage extends StatefulWidget {
  final UserModel user;
  const MySchedulePage({super.key, required this.user});

  @override
  State<MySchedulePage> createState() => _MySchedulePageState();
}

class _MySchedulePageState extends State<MySchedulePage> {
  final ShiftService _shiftService = ShiftService();

  // Start from this Monday
  DateTime _weekStart = _getCurrentMonday();

  static DateTime _getCurrentMonday() {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
  }

  void _previousWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _nextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  String _formatWeekRange() {
    final sunday = _weekStart.add(const Duration(days: 6));
    return "${DateFormat('dd MMM').format(_weekStart)} — ${DateFormat('dd MMM yyyy').format(sunday)}";
  }

  // Check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "MY SCHEDULES",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
        actions: [
          // ── SWAP REQUESTS BUTTON ──
          StreamBuilder<QuerySnapshot>(
            // Show a badge if there are pending incoming swap requests
            stream: FirebaseFirestore.instance
                .collection('swapRequests')
                .where('targetId', isEqualTo: widget.user.uid)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data?.docs.length ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                           padding: const EdgeInsets.only(right: 15, top: 8, bottom: 8),
                    child: SizedBox(
                      width: 145,
                      height: 35,
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SwapRequestsPage(user: widget.user),
                          ),
                        ),
                        icon: const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: const Text(
                          "REQUESTS",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Red badge showing pending count
                  if (pendingCount > 0)
                    Positioned(
                      right: 15,
                      top: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            "$pendingCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
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
            child: Column(
              children: [
                // ── WEEK NAVIGATOR ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous week button
                      GestureDetector(
                        onTap: _previousWeek,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),

                      // Week label
                      Column(
                        children: [
                          const Text(
                            "WEEK",
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatWeekRange(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      // Next week button
                      GestureDetector(
                        onTap: _nextWeek,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                // ── DAYS OF WEEK STRIP ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(7, (i) {
                      final day = _weekStart.add(Duration(days: i));
                      final isToday = _isToday(day);
                      final dayLabels = [
                        "MON",
                        "TUE",
                        "WED",
                        "THU",
                        "FRI",
                        "SAT",
                        "SUN",
                      ];
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primaryGreen.withOpacity(0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isToday
                                  ? AppColors.primaryGreen
                                  : Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                dayLabels[i],
                                style: TextStyle(
                                  color: isToday
                                      ? AppColors.primaryGreen
                                      : AppColors.textDim,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${day.day}",
                                style: TextStyle(
                                  color: isToday
                                      ? Colors.white
                                      : AppColors.textDim,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 10),

                // ── SHIFTS LIST ──
                Expanded(
                  child: StreamBuilder<List<ShiftModel>>(
                    stream: _shiftService.getShiftsReport(
                      pumperId: widget.user.uid,
                      startDate: _weekStart,
                      endDate: weekEnd,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }

                      final shifts = snapshot.data ?? [];

                      if (shifts.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Group shifts by date
                      final Map<String, List<ShiftModel>> grouped = {};
                      for (final shift in shifts) {
                        final key = DateFormat('yyyy-MM-dd').format(shift.date);
                        grouped.putIfAbsent(key, () => []).add(shift);
                      }

                      // Sort by date ascending
                      final sortedKeys = grouped.keys.toList()..sort();

                      return ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        children: [
                          // Summary banner
                          _buildSummaryBanner(shifts.length),
                          const SizedBox(height: 15),

                          // One section per day
                          ...sortedKeys.map((dateKey) {
                            final dayShifts = grouped[dateKey]!;
                            final date = DateTime.parse(dateKey);
                            return _buildDaySection(date, dayShifts);
                          }),

                          //const SizedBox(height: 80),
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

  // ── SUMMARY BANNER ──
  Widget _buildSummaryBanner(int totalShifts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("$totalShifts", "SHIFTS\nTHIS WEEK"),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildStatItem("${totalShifts * 12}h", "EST. HOURS"),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildStatItem(totalShifts >= 5 ? "FULL" : "PARTIAL", "WEEK STATUS"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── DAY SECTION ──
  Widget _buildDaySection(DateTime date, List<ShiftModel> shifts) {
    final isToday = _isToday(date);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isToday
              ? AppColors.primaryGreen.withOpacity(0.3)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primaryGreen.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE').format(date).toUpperCase(),
                  style: TextStyle(
                    color: isToday ? AppColors.primaryGreen : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM').format(date),
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
                if (isToday) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "TODAY",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Shift cards for this day
          ...shifts.map((shift) => _buildShiftRow(shift)),
        ],
      ),
    );
  }

  // ── SHIFT ROW ──
  Widget _buildShiftRow(ShiftModel shift) {
    final isDay = shift.shiftType == "Day Shift";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          // Shift type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDay
                  ? Colors.amber.withOpacity(0.1)
                  : Colors.indigo.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDay ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
              color: isDay ? Colors.amber : Colors.indigo[300],
              size: 18,
            ),
          ),

          const SizedBox(width: 14),

          // Shift info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift.shiftType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  isDay ? "07:00 AM — 07:00 PM" : "07:00 PM — 7:00 PM",
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Pump badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.25),
              ),
            ),
            child: Text(
              shift.pumpNumber.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),

          // Auto-assigned badge
          if (shift.isAutoAssigned == true) ...[
            // Add after the isAutoAssigned badge
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RequestSwapPage(user: widget.user, myShift: shift),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.25)),
                ),
                child: const Text(
                  "SWAP",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── EMPTY STATE ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            "No shifts assigned\nfor this week",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "The manager hasn't generated\nthe schedule yet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
