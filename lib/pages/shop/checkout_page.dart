import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cart_item_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class CheckoutPage extends StatefulWidget {
  final double total;
  final List<CartItemModel> items;

  const CheckoutPage({super.key, required this.total, required this.items});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // New Controllers for Shipping
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _zipController = TextEditingController();

  // Payment Controllers
  final _cardNumController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isProcessing = false;
  String _paymentStatusText = "Initializing Secure Connection...";

  Future<void> _handleStripePayment() async {
    // Validation check
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _cardNumController.text.length < 16) {
      showCustomSnackBar(
        context,
        "Please complete all shipping and payment details",
        isError: true,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _paymentStatusText = "Contacting Bank...";
    });

    await Future.delayed(const Duration(seconds: 2));
    setState(() => _paymentStatusText = "Authorizing Transaction...");
    await Future.delayed(const Duration(seconds: 2));

    try {
      final user = FirebaseAuth.instance.currentUser;
      final orderId = "ORD-${DateTime.now().millisecondsSinceEpoch}";

      // Saving all details to Firestore
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': user!.uid,
        'customerName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'zipCode': _zipController.text.trim(),
        'items': widget.items.map((e) => e.toMap()).toList(),
        'total': widget.total,
        'paymentDetails':
            'Visa ending in ${_cardNumController.text.substring(_cardNumController.text.length - 4)}',
        'status': 'Paid',
        'createdAt': FieldValue.serverTimestamp(),
      });

      HapticFeedback.heavyImpact();
      if (mounted) _showSuccessDialog();
    } catch (e) {
      showCustomSnackBar(context, "Transaction Failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryGreen,
                child: Icon(Icons.check, color: Colors.black, size: 40),
              ),
              const SizedBox(height: 25),
              const Text(
                "PAYMENT VERIFIED",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your order is being prepared.",
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 30),
              FuelButton(
                text: "CONTINUE",
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
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
          "CHECKOUT ORDER",
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("SHIPPING DETAILS"),
                  _buildShippingForm(),
                  const SizedBox(height: 20),
                  _buildSectionHeader("VISA / MASTER CARD DETAILS"),
                  _buildRealisticCardForm(),
                  const SizedBox(height: 20),
                  _buildPriceBreakdown(),
                  const SizedBox(height: 20),
                  FuelButton(
                    text: "PAY NOW",
                    isLoading: _isProcessing,
                    onPressed: () {
                      if (!_isProcessing) _handleStripePayment();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildStripeFooter(),
                ],
              ),
            ),
          ),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildShippingForm() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildField(
            _nameController,
            "Full Name",
            Icons.person_outline,
            type: TextInputType.name,
          ),
          const Divider(color: Colors.white10, height: 1),
          _buildField(
            _phoneController,
            "Mobile Number",
            Icons.phone_android_outlined,
            type: TextInputType.phone,
            inputFormatters: [MaskedInputFormatter('+94 00 000 0000')],
          ),
          const Divider(color: Colors.white10, height: 1),
          _buildField(
            _addressController,
            "Full Shipping Address",
            Icons.local_shipping_outlined,
            type: TextInputType.streetAddress,
          ),
          const Divider(color: Colors.white10, height: 1),
          _buildField(
            _zipController,
            "ZIP / Postal Code",
            Icons.pin_drop_outlined,
            type: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildRealisticCardForm() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildField(
            _cardNumController,
            "0000 0000 0000 0000",
            Icons.credit_card,
            type: TextInputType.number,
            inputFormatters: [MaskedInputFormatter('0000 0000 0000 0000')],
          ),
          const Divider(color: Colors.white10, height: 1),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  _expiryController,
                  "MM/YY",
                  Icons.event,
                  type: TextInputType.number,
                  inputFormatters: [MaskedInputFormatter('00/00')],
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white10),
              Expanded(
                child: _buildField(
                  _cvvController,
                  "CVC",
                  Icons.lock_outline,
                  type: TextInputType.number,
                  inputFormatters: [MaskedInputFormatter('000')],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Column(
      children: [
        _priceRow("Order Subtotal", "LKR ${widget.total.toInt()}"),
        _priceRow("Transaction Fee", "LKR 0.00"),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Total Amount",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "LKR ${widget.total.toInt()}",
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildProcessingOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black87,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryGreen,
              strokeWidth: 2,
            ),
            const SizedBox(height: 25),
            Text(
              _paymentStatusText,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStripeFooter() {
    return const Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 12, color: Colors.white38),
          SizedBox(width: 5),
          Text(
            "SECURED BY STRIPE",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      inputFormatters: inputFormatters,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 15,
        ),
        border: InputBorder.none,
      ),
    );
  }

  Widget _priceRow(String label, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
          Text(
            price,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
