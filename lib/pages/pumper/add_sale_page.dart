import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AddSalePageState extends State<AddSalePage>
    with SingleTickerProviderStateMixin {
  final _qtyController = TextEditingController();
  final SalesService _salesService = SalesService();
  final FuelService _fuelService = FuelService();

  FuelTankModel? _selectedTank;
  double _totalPrice = 0.0;
  double _enteredQty = 0.0;
  bool _isLoading = false;
  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _calculatePrice(String value) {
    final double qty = double.tryParse(value) ?? 0;
    setState(() {
      _enteredQty = qty;
      _totalPrice =
          _selectedTank != null ? qty * _selectedTank!.fuelPrice : 0.0;
    });
  }

  bool get _isOverStock =>
      _selectedTank != null &&
      _enteredQty > 0 &&
      _enteredQty > _selectedTank!.currentQuantity;

  double get _stockPercent =>
      _selectedTank != null && _selectedTank!.capacity > 0
          ? (_selectedTank!.currentQuantity / _selectedTank!.capacity)
              .clamp(0.0, 1.0)
          : 0.0;

  Color get _stockColor {
    if (_stockPercent < 0.20) return AppColors.error;
    if (_stockPercent < 0.40) return AppColors.warning;
    return AppColors.primaryGreen;
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

      String fullName =
          "${userDoc['firstName']} ${userDoc['lastName']}";

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
        HapticFeedback.heavyImpact();
        showCustomSnackBar(
          context,
          "Sale Authorized: LKR ${_totalPrice.toStringAsFixed(2)}",
        );
        _qtyController.clear();
        setState(() {
          _selectedTank = null;
          _totalPrice = 0.0;
          _enteredQty = 0.0;
        });
      } else {
        showCustomSnackBar(context, error, isError: true);
      }
    } catch (e) {
      showCustomSnackBar(context, "Error: ${e.toString()}",
          isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "DISPENSE FUEL",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),

                  // ── FUEL SELECTOR ──
                  _buildLabel("SELECT FUEL TYPE"),
                  const SizedBox(height: 10),
                  StreamBuilder<List<FuelTankModel>>(
                    stream: _fuelService.getFuelTanks(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: LinearProgressIndicator(
                                color: AppColors.primaryGreen),
                          ),
                        );
                      }
                      return _buildFuelSelector(snapshot.data!);
                    },
                  ),

                  const SizedBox(height: 15),

                  // ── TANK STATUS (shows after selection) ──
                  if (_selectedTank != null) ...[
                    _buildTankStatusCard(),
                    const SizedBox(height: 15),
                  ],

                  // ── QUANTITY INPUT ──
                  _buildLabel("DISPENSE VOLUME"),
                  const SizedBox(height: 10),
                  
                  _buildQuantityInput(),

                  const SizedBox(height: 15),

                  // ── TRANSACTION CARD ──
                  _buildTransactionCard(),

                  const SizedBox(height: 20),

                  // ── ACTION BUTTON ──
                  FuelButton(
                    text: "PROCESS TRANSACTION",
                    isLoading: _isLoading,
                    onPressed: _handleProcessSale,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FUEL SELECTOR ──
  Widget _buildFuelSelector(List<FuelTankModel> tanks) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _selectedTank != null
              ? _stockColor.withOpacity(0.2)
              : AppColors.primaryGreen.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FuelTankModel>(
          hint: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              "Choose fuel type...",
              style: TextStyle(
                  color: AppColors.textDim, fontSize: 13),
            ),
          ),
          value: _selectedTank,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(Icons.keyboard_arrow_down,
                color: AppColors.primaryGreen, size: 22),
          ),
          items: tanks.map((tank) {
            final double pct =
                (tank.currentQuantity / tank.capacity).clamp(0.0, 1.0);
            final Color c = pct < 0.20
                ? AppColors.error
                : pct < 0.40
                    ? AppColors.warning
                    : AppColors.primaryGreen;
            return DropdownMenuItem<FuelTankModel>(
              value: tank,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: c),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tank.fuelType,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                    Text(
                      "LKR ${tank.fuelPrice.toInt()}/L",
                      style: TextStyle(
                          color: AppColors.textDim, fontSize: 11),
                    ),
                  ],
                ),
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
  }

  // ── TANK STATUS CARD ──
  Widget _buildTankStatusCard() {
    final tank = _selectedTank!;
    final double pct = _stockPercent;
    final double pctVal = pct * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
       // color: _stockColor.withOpacity(0.06),
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _stockColor.withOpacity(0.2),    width: 1.5,),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.storage_outlined,
                  color: _stockColor, size: 16),
              const SizedBox(width: 8),
              Text(
                "TANK STATUS — ${tank.fuelType.toUpperCase()}",
                style: TextStyle(
                  color: _stockColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                "${pctVal.toStringAsFixed(1)}% FULL",
                style: TextStyle(
                  color: _stockColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                    height: 6,
                    color: Colors.white.withOpacity(0.06)),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        _stockColor.withOpacity(0.6),
                        _stockColor,
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMicroStat("AVAILABLE",
                  "${tank.currentQuantity.toStringAsFixed(0)} L",
                  _stockColor),
              _buildMicroStat("CAPACITY",
                  "${tank.capacity.toStringAsFixed(0)} L",
                  AppColors.textDim),
              _buildMicroStat("PRICE",
                  "LKR ${tank.fuelPrice.toInt()}/L",
                  AppColors.secondaryGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicroStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.textDim,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color == AppColors.textDim
                    ? Colors.white60
                    : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── QUANTITY INPUT ──
  Widget _buildQuantityInput() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _isOverStock
                  ? AppColors.error.withOpacity(0.5)
                  : AppColors.primaryGreen.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.water_drop_outlined,
                  color: _isOverStock
                      ? AppColors.error
                      : AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "Enter litres...",
                    hintStyle: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 14,
                        fontWeight: FontWeight.normal),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 18),
                  ),
                  onChanged: _calculatePrice,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "LITRES",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Overflow warning
        if (_isOverStock) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 14),
              const SizedBox(width: 6),
              Text(
                "Exceeds available stock of ${_selectedTank!.currentQuantity.toStringAsFixed(1)}L",
                style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── TRANSACTION CARD ──
  Widget _buildTransactionCard() {
    final bool hasData =
        _selectedTank != null && _enteredQty > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isOverStock
                  ? AppColors.error.withOpacity(0.2)
                  : AppColors.primaryGreen.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Total amount
              Text(
                "TRANSACTION TOTAL",
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  "LKR ${_totalPrice.toStringAsFixed(2)}",
                  key: ValueKey(_totalPrice),
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: _isOverStock
                        ? AppColors.error
                        : Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 5),
              Divider(color: Colors.white.withOpacity(0.06)),
              const SizedBox(height: 10),

              // Details
              _buildReceiptRow(
                Icons.local_gas_station_outlined,
                "Fuel Type",
                _selectedTank?.fuelType ?? "—",
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(
                Icons.water_drop_outlined,
                "Volume",
                hasData
                    ? "${_enteredQty.toStringAsFixed(2)} L"
                    : "—",
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(
                Icons.payments_outlined,
                "Unit Rate",
                _selectedTank != null
                    ? "LKR ${_selectedTank!.fuelPrice.toStringAsFixed(2)}"
                    : "—",
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(
                _isOverStock
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                "System Status",
                _isOverStock ? "Insufficient Stock" : "Ready",
                valueColor: _isOverStock
                    ? AppColors.error
                    : AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textDim),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: AppColors.textDim, fontSize: 12)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      );
}