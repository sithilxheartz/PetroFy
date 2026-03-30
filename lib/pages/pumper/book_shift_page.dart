import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/shift_model.dart';
import '../../models/user_model.dart';
import '../../services/shift_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class BookShiftPage extends StatefulWidget {
  final UserModel user;
  const BookShiftPage({super.key, required this.user});

  @override
  State<BookShiftPage> createState() => _BookShiftPageState();
}

class _BookShiftPageState extends State<BookShiftPage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = "Day Shift";
  String _selectedPump = "Petrol 01";
  bool _isLoading = false;

  void _handleBooking() async {
    setState(() => _isLoading = true);

    ShiftModel newRequest = ShiftModel(
      pumperId: widget.user.uid,
      pumperName: "${widget.user.firstName} ${widget.user.lastName}",
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
      shiftType: _selectedShift,
      pumpNumber: _selectedPump,
      status: 'accepted',
    );

    String? result = await ShiftService().requestShift(newRequest);

    if (mounted) setState(() => _isLoading = false);

    if (result == null) {
      showCustomSnackBar(context, "Shift Confirmed Successfully!");
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
    } else {
      showCustomSnackBar(context, result, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 15),
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "RESERVE YOUR SHIFT",
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold,),
                  ),
                  const Text(
                    "Select your shift schedule details below.",
                    style: TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                  const SizedBox(height: 15),

                  // 1. DATE SELECTION
                  _buildLabel("SELECT DATE"),
                  const SizedBox(height: 10),
                  _buildGlassBox(
                    child: ListTile(
                      title: Text(
                        "${_selectedDate.day} - 0${_selectedDate.month} - ${_selectedDate.year}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: AppColors.primaryGreen),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 14)),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 2. SHIFT SELECTION (Using Interactive Tiles for "Interest")
                  _buildLabel("SELECT SHIFT DURATION"),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildShiftTile("Day Shift", Icons.wb_sunny_outlined),
                      const SizedBox(width: 15),
                      _buildShiftTile("Night Shift", Icons.nights_stay_outlined),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // 3. PUMP NUMBER SELECTION
                  _buildLabel("SELECT PUMP NUMBER"),
                  const SizedBox(height: 10),
                  _buildGlassDropdown(
                    [
                      "Petrol 01",
                      "Petrol 02",
                      "Diesel 01",
                      "Diesel 02",
                      "Super Petrol",
                      "Super Diesel",
                    ],
                    _selectedPump,
                    (v) => setState(() => _selectedPump = v!),
                  ),

                  const SizedBox(height: 20),

                  // ACTION BUTTON
                  FuelButton(
                    text: "CONFIRM SHIFT",
                    isLoading: _isLoading,
                    onPressed: _handleBooking,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Section Labels
  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      );

  // Custom Interactive Shift Tiles
  Widget _buildShiftTile(String type, IconData icon) {
    bool isSelected = _selectedShift == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedShift = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen.withOpacity(0.15) : AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? AppColors.primaryGreen : Colors.white10,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primaryGreen : AppColors.textDim, size: 24),
              const SizedBox(height: 8),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDim,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBox({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1)),
        ),
        child: child,
      );

  Widget _buildGlassDropdown(List<String> items, String value, Function(String?) onChanged) => _buildGlassBox(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            icon: const Padding(
              padding: EdgeInsets.only(right: 15),
              child: Icon(Icons.arrow_drop_down, color: AppColors.textDim),
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        e,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );
}