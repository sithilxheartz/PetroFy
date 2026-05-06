import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/fuel_sale_model.dart';
import '../../models/fuel_tank_model.dart';
import '../../services/fuel_service.dart';
import '../../services/sales_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class AddSalePage extends StatefulWidget {
  const AddSalePage({super.key});

  @override
  State<AddSalePage> createState() => _AddSalePageState();
}

class _AddSalePageState extends State<AddSalePage> {
  final _qtyController = TextEditingController();
  final SalesService _salesService = SalesService();
  final FuelService _fuelService = FuelService();

  FuelTankModel? _selectedTank;
  double _totalPrice = 0.0;
  bool _isLoading = false;

  void _calculatePrice(String value) {
    double qty = double.tryParse(value) ?? 0;
    if (_selectedTank != null) {
      setState(() {
        _totalPrice = qty * _selectedTank!.fuelPrice;
      });
    }
  }

  void _handleProcessSale() async {
    final String rawQty = _qtyController.text.trim();
    final double enteredQty = double.tryParse(rawQty) ?? 0;

    if (_selectedTank == null || rawQty.isEmpty || enteredQty <= 0) {
      showCustomSnackBar(
        context,
        "Please select fuel and enter a valid quantity",
        isError: true,
      );
      return;
    }

    if (enteredQty > _selectedTank!.currentQuantity) {
      showCustomSnackBar(
        context,
        "Insufficient Stock! Only ${_selectedTank!.currentQuantity.toStringAsFixed(1)}L available.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      String fullName = "${userDoc['firstName']} ${userDoc['lastName']}";

      FuelSaleModel newSale = FuelSaleModel(
        fuelType: _selectedTank!.fuelType,
        dateTime: DateTime.now(),
        pumperName: fullName,
        pumperId: user.uid,
        soldQuantity: enteredQty,
        tankId: _selectedTank!.id,
        soldTotalPrice: _totalPrice,
      );

      String? error = await _salesService.recordSale(newSale);

      if (error == null) {
        showCustomSnackBar(
          context,
          "Sale Authorized: LKR ${_totalPrice.toStringAsFixed(2)}",
        );
        _qtyController.clear();
        setState(() {
          _selectedTank = null;
          _totalPrice = 0.0;
        });
      } else {
        showCustomSnackBar(context, error, isError: true);
      }
    } catch (e) {
      showCustomSnackBar(context, "Error: ${e.toString()}", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "DISPENSE FUEL SALE",
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // 1. Fuel Type Selection
                  _buildSectionLabel("SELECT FUEL TYPE"),
                  const SizedBox(height: 10),
                  StreamBuilder<List<FuelTankModel>>(
                    stream: _fuelService.getFuelTanks(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator(
                          color: AppColors.primaryGreen,
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<FuelTankModel>(
                            hint: const Text("Select Fuel Product"),
                            value: _selectedTank,
                            isExpanded: true,
                            dropdownColor: AppColors.surface,
                            items: snapshot.data!.map((tank) {
                              return DropdownMenuItem<FuelTankModel>(
                                value: tank,
                                child: Text(
                                  "${tank.fuelType} (LKR ${tank.fuelPrice}/L)",
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedTank = val;
                                _calculatePrice(_qtyController.text);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  // 2. Quantity Input
                  _buildSectionLabel("DISPENSE VOLUME"),
                  const SizedBox(height: 10),
                  FuelNumberField(
                    // Using the specialized numeric widget
                    controller: _qtyController,
                    label: "Quantity in Liters",
                    icon: Icons.water_drop_outlined,
                    onChanged: _calculatePrice,
                  ),

                  const SizedBox(height: 20),

                  // 3. Digital Receipt Card with Stock Info
                  _buildReceiptCard(),

                  const SizedBox(height: 20),

                  // 4. Action Button
                  FuelButton(
                    text: "PROCESS TRANSACTION",
                    isLoading: _isLoading,
                    onPressed: _handleProcessSale,
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

  // --- UI HELPER WIDGETS ---

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primaryGreen,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildReceiptCard() {
    double enteredQty = double.tryParse(_qtyController.text) ?? 0;
    bool isOverStock =
        _selectedTank != null && enteredQty > _selectedTank!.currentQuantity;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              const Text(
                "TRANSACTION TOTAL",
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "LKR ${_totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              const Divider(color: Colors.white10, thickness: 1),
              const SizedBox(height: 10),

              _buildReceiptRow(
                "Available Stock",
                _selectedTank != null
                    ? "${_selectedTank!.currentQuantity.toStringAsFixed(1)} L"
                    : "--",
              ),
              _buildReceiptRow(
                "Unit Rate",
                "LKR ${_selectedTank?.fuelPrice.toStringAsFixed(2) ?? "0.00"}",
              ),
              _buildReceiptRow(
                "System Status",
                isOverStock ? "Insufficient Stock" : "System Ready",
                valueColor: isOverStock
                    ? Colors.redAccent
                    : AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    Color valueColor = Colors.white70,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
