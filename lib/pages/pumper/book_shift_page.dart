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
  String _selectedShift = "Day";
  String _selectedPump = "Pump 01";
  bool _isLoading = false;

  void _handleBooking() async {
    setState(() => _isLoading = true);

    ShiftModel newRequest = ShiftModel(
      pumperId: widget.user.uid,
      pumperName: "${widget.user.firstName} ${widget.user.lastName}",
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day), // Normalize to midnight
      shiftType: _selectedShift,
      pumpNumber: _selectedPump,
    );

    String? result = await ShiftService().requestShift(newRequest);

    setState(() => _isLoading = false);

    if (result == null) {
      showCustomSnackBar(context, "Shift Requested Successfully!");
    } else {
      showCustomSnackBar(context, result, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow Decoration
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
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("SCHEDULE SHIFT", 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const Text("Request your preferred work slot", 
                    style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                  const SizedBox(height: 35),

                  // 1. Date Selection Card (Glass)
                  _buildGlassLabel("ASSIGNMENT DATE"),
                  const SizedBox(height: 10),
                  _buildGlassContainer(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      title: Text(
                        "${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.calendar_month, color: AppColors.primaryGreen),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 14)),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primaryGreen)),
                            child: child!,
                          ),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 2. Shift Type Dropdown
                  _buildGlassLabel("SHIFT PERIOD"),
                  const SizedBox(height: 10),
                  _buildGlassDropdown(
                    value: _selectedShift,
                    items: ["Day", "Night"],
                    onChanged: (val) => setState(() => _selectedShift = val!),
                  ),

                  const SizedBox(height: 25),

                  // 3. Pump Selection Dropdown
                  _buildGlassLabel("PUMP STATION"),
                  const SizedBox(height: 10),
                  _buildGlassDropdown(
                    value: _selectedPump,
                    items: ["Pump 01", "Pump 02", "Pump 03", "Pump 04", "Pump 05", "Pump 06"],
                    onChanged: (val) => setState(() => _selectedPump = val!),
                  ),

                  const SizedBox(height: 40),

                  // 4. Submit Button
                  FuelButton(
                    text: "SUBMIT REQUEST", 
                    isLoading: _isLoading, 
                    onPressed: _handleBooking
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helper Components ---

  Widget _buildGlassLabel(String text) {
    return Text(text, style: const TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5));
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    return _buildGlassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}