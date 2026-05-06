import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_model.dart';
import '../../models/user_model.dart';
import '../../services/shift_service.dart';
import '../../utils/app_colors.dart';
import 'book_shift_page.dart';
import 'swap_requests_page.dart';

class ShiftViewPage extends StatefulWidget {
  final UserModel user;
  const ShiftViewPage({super.key, required this.user});

  @override
  State<ShiftViewPage> createState() => _ShiftViewPageState();
}

class _ShiftViewPageState extends State<ShiftViewPage> {
  DateTime _selectedDate = DateTime.now();
  final ShiftService _shiftService = ShiftService();

  void _showBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: BookShiftPage(user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "SHIFT ROSTER",
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
          Positioned(top: -50, right: -50, child: _buildGlow()),
          SafeArea(
            child: Column(
              children: [
                _buildDateSelector(),
                Expanded(
                  child: StreamBuilder<List<ShiftModel>>(
                    stream: _shiftService.getShiftsByDate(_selectedDate),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }
                      final shifts = snapshot.data ?? [];
                      return ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        children: [
                          _buildShiftSection(
                            "DAY SHIFT",
                            Icons.sunny,
                            shifts
                                .where((s) => s.shiftType == "Day Shift")
                                .toList(),
                          ),
                          const SizedBox(height: 15),
                          _buildShiftSection(
                            "NIGHT SHIFT",
                            Icons.nights_stay_outlined,
                            shifts
                                .where((s) => s.shiftType == "Night Shift")
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

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: GestureDetector(
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 7)),
            lastDate: DateTime.now().add(const Duration(days: 14)),
          );
          if (picked != null) setState(() => _selectedDate = picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMMM yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              const Icon(
                Icons.calendar_month,
                size: 18,
                color: AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftSection(
    String title,
    IconData icon,
    List<ShiftModel> shifts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            const Spacer(),
            // shift count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${shifts.length} pumpers",
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        shifts.isEmpty
            ? const Text(
                "No deployments found",
                style: TextStyle(color: Colors.white10, fontSize: 12),
              )
            : Column(children: shifts.map((s) => _buildPumperCard(s)).toList()),
      ],
    );
  }

  Widget _buildPumperCard(ShiftModel shift) {
    // Highlight if this card belongs to the logged-in pumper
    final isMe = shift.pumperId == widget.user.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primaryGreen.withOpacity(0.08)
            : AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isMe
              ? AppColors.primaryGreen.withOpacity(0.25)
              : Colors.white.withOpacity(0.03),
        ),
      ),
      child: Row(
        children: [
          // Profile picture
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(shift.pumperId)
                .get(),
            builder: (context, snapshot) {
              String imgUrl =
                  "https://ui-avatars.com/api/?name=${shift.pumperName}&background=00E676&color=fff";
              if (snapshot.hasData && snapshot.data!.exists) {
                imgUrl = snapshot.data!['profilePic'] ?? imgUrl;
              }
              return CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(imgUrl),
                backgroundColor: AppColors.background,
              );
            },
          ),

          const SizedBox(width: 15),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      shift.pumperName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "YOU",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Text(
                  "VERIFIED FUEL PUMPER",
                  style: TextStyle(
                    fontSize: 8,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Pump badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.2),
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
        ],
      ),
    );
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
