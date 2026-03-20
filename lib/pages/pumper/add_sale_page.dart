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
    if (_selectedTank == null || _qtyController.text.isEmpty) {
      showCustomSnackBar(
        context,
        "Please select fuel and enter quantity",
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
        soldQuantity: double.parse(_qtyController.text),
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
            extendBodyBehindAppBar:
          true, // Allows content to scroll under the blurred AppBar
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              "DISPENSE FUEL SALES",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
                fontSize: 20,
              ),
            ),
          ],
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
            width: 200, // Slightly larger for better effect
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen.withOpacity(0.05), // Increased opacity slightly
            ),
          ),
        ),
        Container(
                margin: const EdgeInsets.only(top: 85, bottom: 40),
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        color: AppColors.primaryGreen.withOpacity(0.2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<FuelTankModel>(
                        hint: const Text("Select Fuel Type"),
                        value: _selectedTank,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        // FIXED: The map now returns the object, and == handles the rest
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
              const SizedBox(height: 20),

              FuelTextField(
                controller: _qtyController,
                label: "Sold Quantity (Liters)",
                icon: Icons.water_drop_outlined,
                onChanged: _calculatePrice,
              ),

              const SizedBox(height: 20),

              // Digital Receipt Card
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "TRANSACTION TOTAL",
                          style: TextStyle(
                            color: Colors.white,
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
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white10),
                        _buildReceiptRow(
                          "Rate",
                          "LKR ${_selectedTank?.fuelPrice ?? 0.00}",
                        ),
                        _buildReceiptRow("Status", "Ready for Auth"),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
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
      )
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
