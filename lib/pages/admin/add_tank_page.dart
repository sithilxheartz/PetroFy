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
  final _priceController = TextEditingController(); // <--- New Controller
  
  final FuelService _fuelService = FuelService();
  bool _isLoading = false;

  void _saveTank() async {
    if (_typeController.text.isEmpty || _priceController.text.isEmpty) {
      showCustomSnackBar(context, "Please enter fuel type and price", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    FuelTankModel newTank = FuelTankModel(
      id: '',
      fuelType: _typeController.text.trim(),
      capacity: double.tryParse(_capacityController.text) ?? 0,
      currentQuantity: double.tryParse(_quantityController.text) ?? 0,
      fuelPrice: double.tryParse(_priceController.text) ?? 0, // <--- Parse Price
      lastRefillDate: DateTime.now(),
    );

    await _fuelService.addFuelTank(newTank);
    
    setState(() => _isLoading = false);
    if (mounted) {
      showCustomSnackBar(context, "Tank Configured with Price: LKR ${_priceController.text}");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Hardware Config"), backgroundColor: Colors.transparent),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [AppColors.primaryGreen.withOpacity(0.05), AppColors.background],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              // 1. Fuel Type & Price in a Row
              Row(
                children: [
                  Expanded(flex: 2, child: FuelTextField(controller: _typeController, label: "Fuel Type", icon: Icons.gas_meter)),
                  const SizedBox(width: 15),
                  Expanded(flex: 1, child: FuelTextField(controller: _priceController, label: "Price (LKR)", icon: Icons.payments_outlined)),
                ],
              ),

              // 2. Capacity & Current Level
              Row(
                children: [
                  Expanded(child: FuelTextField(controller: _capacityController, label: "Max Cap (L)", icon: Icons.straighten)),
                  const SizedBox(width: 15),
                  Expanded(child: FuelTextField(controller: _quantityController, label: "Current (L)", icon: Icons.water_drop)),
                ],
              ),

              const SizedBox(height: 30),
              FuelButton(text: "INITIALIZE TANK", isLoading: _isLoading, onPressed: _saveTank),
            ],
          ),
        ),
      ),
    );
  }
}