import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_model.dart';
import '../../models/user_model.dart';
import '../../services/shift_service.dart';
import '../../utils/app_colors.dart';
import 'book_shift_page.dart';

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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15, top: 8, bottom: 8),
            child: TextButton.icon(
              onPressed: _showBookingSheet,
              icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 18),
              label: const Text(
                "BOOK SHIFT",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.1), width: 1.5),
                ),
              ),
            ),
          ),
        ],
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
                        return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                      }
                      final shifts = snapshot.data ?? [];
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        children: [
                          _buildShiftSection("DAY SHIFT", Icons.sunny, shifts.where((s) => s.shiftType == "Day Shift").toList()),
                          const SizedBox(height: 15),
                          _buildShiftSection("NIGHT SHIFT", Icons.nights_stay_outlined, shifts.where((s) => s.shiftType == "Night Shift").toList()),
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
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDim)),
              const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryGreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftSection(String title, IconData icon, List<ShiftModel> shifts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDim)),
          ],
        ),
        const SizedBox(height: 15),
        shifts.isEmpty
            ? const Text("No deployments found", style: TextStyle(color: Colors.white10, fontSize: 12))
            : Column(children: shifts.map((s) => _buildPumperCard(s)).toList()),
      ],
    );
  }

  Widget _buildPumperCard(ShiftModel shift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(shift.pumperId).get(),
            builder: (context, snapshot) {
              String imgUrl = "https://ui-avatars.com/api/?name=${shift.pumperName}&background=00E676&color=fff";
              if (snapshot.hasData && snapshot.data!.exists) {
                imgUrl = snapshot.data!['profilePic'] ?? imgUrl;
              }
              return CircleAvatar(radius: 20, backgroundImage: NetworkImage(imgUrl), backgroundColor: AppColors.background);
            },
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shift.pumperName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text("ACTIVE ASSIGNMENT", style: TextStyle(fontSize: 8, color: AppColors.primaryGreen, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
            ),
            child: Text(shift.pumpNumber.toUpperCase(), style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow() {
    return Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen.withOpacity(0.05)));
  }
}