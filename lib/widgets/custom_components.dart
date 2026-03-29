import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';

class FuelTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final Function(String)? onChanged;
  // --- ADD THESE TWO LINES ---
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const FuelTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.onChanged,
    this.keyboardType = TextInputType.text, // Default to text
    this.inputFormatters, // Default to null
  });

  @override
  State<FuelTextField> createState() => _FuelTextFieldState();
}

class _FuelTextFieldState extends State<FuelTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      // --- ADD THESE TWO LINES ---
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      
      obscureText: widget.isPassword ? _obscureText : false,
      style: const TextStyle(color: AppColors.textMain),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon, color: AppColors.primaryGreen),
        // ... rest of your existing decoration ...
      ),
    );
  }
}

// 2. The Glowing Action Button
class FuelButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const FuelButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: AppColors.primaryGreen.withOpacity(0.4),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: AppColors.background)
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

void showCustomSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.background,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isError ? AppColors.error : AppColors.primaryGreen,
      behavior:
          SnackBarBehavior.floating, // Makes it float above the bottom nav
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(20), // Adds padding around the floating bar
    ),
  );
}
