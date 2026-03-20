import 'package:flutter/material.dart';
import '../../services/fuel_service.dart';
import '../../models/fuel_tank_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class AddTankPage extends StatefulWidget {
  const AddTankPage({super.key});

  @override
  State<AddTankPage> createState() => _AddTankPageState();
}

class _AddTankPageState extends State<AddTankPage> {
  final _typeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _quantityController = TextEditingController();
  final FuelService _fuelService = FuelService();
  bool _isLoading = false;

  void _saveTank() async {
    if (_typeController.text.isEmpty || _capacityController.text.isEmpty) {
      showCustomSnackBar(context, "Please fill all details", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    FuelTankModel newTank = FuelTankModel(
      id: '', // Firestore generates this
      fuelType: _typeController.text.trim(),
      capacity: double.parse(_capacityController.text),
      currentQuantity: double.parse(_quantityController.text),
      lastRefillDate: DateTime.now(),
    );

    await _fuelService.addFuelTank(newTank);

    setState(() => _isLoading = false);
    if (mounted) {
      showCustomSnackBar(context, "Fuel Tank Integrated Successfully");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Register Fuel Tank"),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              AppColors.primaryGreen.withOpacity(0.05),
              AppColors.background,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hardware Configuration",
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              FuelTextField(
                controller: _typeController,
                label: "Fuel Type (e.g. 92 Octane)",
                icon: Icons.local_gas_station,
              ),

              Row(
                children: [
                  Expanded(
                    child: FuelTextField(
                      controller: _capacityController,
                      label: "Max Capacity (L)",
                      icon: Icons.unfold_more,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: FuelTextField(
                      controller: _quantityController,
                      label: "Initial Level (L)",
                      icon: Icons.water_drop,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              FuelButton(
                text: "ADD TO SYSTEM",
                isLoading: _isLoading,
                onPressed: _saveTank,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
