import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:petrofy/pages/admin/order_history_popup_page.dart';
import '../../models/fuel_order_model.dart';
import '../../models/user_model.dart';
import '../../services/order_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class AddOrderPage extends StatefulWidget {
  final UserModel adminUser;
  const AddOrderPage({super.key, required this.adminUser});

  @override
  State<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();

  String _selectedFuel = '92 Petrol';
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _receiptController = TextEditingController();
  final TextEditingController _bowserController = TextEditingController();

  bool _isLoading = false;
  double _availableSpace = 0.0; // Tracks space in selected tank

  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      // Final safety check before submisson
      double inputQty = double.tryParse(_qtyController.text) ?? 0;
      if (inputQty > _availableSpace) {
        showCustomSnackBar(
          context,
          "Cannot exceed available space!",
          isError: true,
        );
        return;
      }

      setState(() => _isLoading = true);

      final order = FuelOrderModel(
        orderDate: DateTime.now(),
        fuelType: _selectedFuel,
        quantity: inputQty,
        confirmedAdminId: widget.adminUser.uid,
        confirmedAdminName:
            "${widget.adminUser.firstName} ${widget.adminUser.lastName}",
        receiptNumber: _receiptController.text,
        bowserNumber: _bowserController.text.toUpperCase(),
        status: 'delivered',
      );

      try {
        await _orderService.createOrderAndUpdateStock(order);
        if (mounted) {
          showCustomSnackBar(context, "Stock Successfully Replenished");
          _qtyController.clear();
          _receiptController.clear();
          _bowserController.clear();
        }
      } catch (e) {
        if (mounted) showCustomSnackBar(context, e.toString(), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "NEW FUEL ORDER",
          style: TextStyle(
            fontWeight: FontWeight.bold,
                  fontSize: 21,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15, top: 8, bottom: 8),
            child: Container(
              width: 155,
              height: 35,
              child: TextButton.icon(
                onPressed: _showHistoryPopup,
                icon: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "HISTORY",
                  style: TextStyle(
                    color: Colors.white,
                 //   fontWeight: FontWeight.bold,
                  ),
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
        ],
      ),
      body: Stack(
        children: [
          // Theme Glows
          Positioned(top: -50, right: -50, child: _buildGlow()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LIVE TANK STATUS WITH AVAILABLE SPACE
                    _buildLiveTankPreview(),

                    const SizedBox(height: 15),

                    _buildFrostedContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("SELECT FUEL TYPE"),
                          _buildDropdown(),
                          const SizedBox(height: 20),

                          _buildLabel("INTAKE QUANTITY (L)"),
                          ValueListenableBuilder(
                            valueListenable: _qtyController,
                            builder: (context, value, child) {
                              double input = double.tryParse(value.text) ?? 0;
                              bool isOverflow =
                                  input > _availableSpace &&
                                  _availableSpace > 0;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputField(
                                    controller: _qtyController,
                                    hint: "Enter liters...",
                                    icon: Icons.add_business_rounded,
                                    keyboardType: TextInputType.number,
                                    isError: isOverflow,
                                    validator: (val) {
                                      if (val == null || val.isEmpty)
                                        return "Required";
                                      double? n = double.tryParse(val);
                                      if (n == null || n < 1000)
                                        return "Min 1000L";
                                      if (n > _availableSpace)
                                        return "Exceeds Capacity!";
                                      return null;
                                    },
                                  ),
                                  if (isOverflow)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 5, left: 5),
                                      child: Text(
                                        "⚠️ Overfilling detected!",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 20),
                          _buildLabel("INVOICE NUMBER"),
                          _buildInputField(
                            controller: _receiptController,
                            hint: "RECXXXXXX",
                            icon: Icons.receipt_outlined,
                          ),

                          const SizedBox(height: 20),
                          _buildLabel("BOWSER REGISTRATION NO"),
                          _buildInputField(
                            controller: _bowserController,
                            hint: "LP-XXXX",
                            icon: Icons.local_shipping_outlined,
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Required";
                              if (!RegExp(
                                r'^[A-Z]{2,3}-\d{4}$',
                              ).hasMatch(val.toUpperCase()))
                                return "Invalid Format";
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),
                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryGreen,
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _submitOrder,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      disabledBackgroundColor: Colors.white10,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Text(
                                      "CONFIRM INTAKE",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTankPreview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fuelTanks')
          .where('fuelType', isEqualTo: _selectedFuel)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox();
        var tank = snapshot.data!.docs.first;
        double current = (tank['currentQuantity'] as num).toDouble();
        double capacity = (tank['capacity'] as num).toDouble();
        _availableSpace = capacity - current;

        return _buildFrostedContainer(
          child: Row(
            children: [
              _buildSimpleGauge(current / capacity),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TANK STATUS: $_selectedFuel",
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Available Space: ${_availableSpace.toStringAsFixed(0)} L",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Current Load: ${current.toStringAsFixed(0)}L / ${capacity.toStringAsFixed(0)}L",
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleGauge(double percent) {
    return Container(
      width: 55,
      height: 55,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12),
      ),
      child: CircularProgressIndicator(
        value: percent,
        strokeWidth: 12,
        backgroundColor: Colors.white10,
        color: percent > 0.9 ? Colors.redAccent : AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildFrostedContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.primaryGreen,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isError = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(
          icon,
          color: isError ? Colors.redAccent : AppColors.primaryGreen,
          size: 18,
        ),
        filled: true,
        fillColor: AppColors.background,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            width: 1.5,
            color: isError
                ? Colors.redAccent
                : const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isError ? Colors.redAccent : AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  void _showHistoryPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 15),
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "FUEL ORDER HISTORY",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.primaryGreen,
                  fontSize: 14,
                ),
              ),
              const Expanded(child: OrderHistoryPopup()), // 👈 Your new widget
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedFuel,
        dropdownColor: AppColors.surface,
        style: TextStyle(
          color: Colors.white,
       //   fontSize: 14,
               fontFamily: GoogleFonts.poppins().fontFamily,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(border: InputBorder.none),
        items: [
          '92 Petrol',
          '95 Petrol',
          'Auto Diesel',
          'Super Diesel',
        ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
        onChanged: (val) => setState(() {
          _selectedFuel = val!;
          _qtyController.clear(); // Clear qty when switching fuel types
        }),
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
