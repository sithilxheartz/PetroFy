import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class PriceConfigPage extends StatefulWidget {
  const PriceConfigPage({super.key});

  @override
  State<PriceConfigPage> createState() => _PriceConfigPageState();
}

class _PriceConfigPageState extends State<PriceConfigPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Map to store controllers for each fuel tank dynamically
  final Map<String, TextEditingController> _controllers = {};

  // --- 1. Confirmation Dialog Logic ---
  void _confirmPriceChange(
    String tankId,
    String fuelType,
    String newPriceText,
  ) {
    double? price = double.tryParse(newPriceText);

    if (price == null || price <= 0) {
      showCustomSnackBar(
        context,
        "Please enter a valid numeric price",
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surface.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.2)),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 10),
              const Text(
                "Confirm Price Update",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to update the rate for $fuelType to LKR ${price.toStringAsFixed(2)} per liter?",
            style: const TextStyle(color: AppColors.textDim, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CANCEL",
                style: TextStyle(color: Colors.white38),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 5),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _executePriceUpdate(tankId, fuelType, price);
                },
                child: const Text(
                  "UPDATE NOW",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Database Execution ---
  Future<void> _executePriceUpdate(
    String tankId,
    String fuelType,
    double price,
  ) async {
    try {
      await _firestore.collection('fuelTanks').doc(tankId).update({
        'fuelPrice': price,
      });

      if (mounted) {
        showCustomSnackBar(
          context,
          "Price Updated: $fuelType @ LKR ${price.toStringAsFixed(2)}",
        );
        // Remove focus from text field after success
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          "Update Failed: ${e.toString()}",
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "PRICE CONFIGURATION",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
            fontSize: 21,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildGlow()),
          Positioned(bottom: -50, left: -50, child: _buildGlow()),

          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('fuelTanks').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(
                    child: Text(
                      "Connection Error",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                if (!snapshot.hasData)
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  );

                final tanks = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  itemCount: tanks.length,
                  itemBuilder: (context, index) {
                    final tank = tanks[index];
                    final String tankId = tank.id;
                    final String fuelType = tank['fuelType'];
                    final double currentPrice = (tank['fuelPrice'] as num)
                        .toDouble();

                    // Maintain controller text consistency
                    if (!_controllers.containsKey(tankId)) {
                      _controllers[tankId] = TextEditingController(
                        text: currentPrice.toString(),
                      );
                    }

                    return _buildPriceCard(tankId, fuelType, currentPrice);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(String id, String type, double currentPrice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:AppColors.primaryGreen.withOpacity(0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  "LKR ${currentPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: FuelNumberField(
                  controller: _controllers[id]!,
                  label: "Set New Rate",
                  icon: Icons.price_change,
                ),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () =>
                    _confirmPriceChange(id, type, _controllers[id]!.text),
                child: Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.done_all_rounded,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
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
