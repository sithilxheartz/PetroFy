import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_components.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // All Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Custom Styled Date Picker
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryGreen,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
            ),
            dialogBackgroundColor: AppColors.background,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _handleSignUp() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _firstNameController.text.isEmpty) {
      showCustomSnackBar(
        context,
        "Please fill in all required fields",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    String? error = await _authService.signUpUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      dob: _dobController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (error == null) {
      showCustomSnackBar(context, "Account Created Successfully!");
      Navigator.pop(context);
    } else {
      showCustomSnackBar(context, error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          // Matching the Login Page Gradient
          gradient: RadialGradient(
            center:
                Alignment.bottomRight, // Mirror the login gradient for variety
            radius: 1.5,
            colors: [
              AppColors.primaryGreen.withOpacity(0.05),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 60,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "CREATE ACCOUNT",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const Text(
                    "Join the Petrofy AI network",
                    style: TextStyle(color: AppColors.textDim, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  // Name Row
                  Row(
                    children: [
                      Expanded(
                        child: FuelTextField(
                          controller: _firstNameController,
                          label: "First Name",
                          icon: Icons.person,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: FuelTextField(
                          controller: _lastNameController,
                          label: "Last Name",
                          icon: Icons.person_outline,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  FuelTextField(
                    controller: _emailController,
                    label: "Email Address",
                    icon: Icons.alternate_email,
                  ),
                  SizedBox(height: 10),
                  FuelTextField(
                    controller: _mobileController,
                    label: "Mobile Number",
                    icon: Icons.phone_android,
                  ),
                  SizedBox(height: 10),
                  // DOB with gesture detector for the popup
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: FuelTextField(
                        controller: _dobController,
                        label: "Date of Birth",
                        icon: Icons.calendar_month,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  FuelTextField(
                    controller: _passwordController,
                    label: "Password",
                    icon: Icons.lock_reset,
                    isPassword: true,
                  ),

                  const SizedBox(height: 25),
                  FuelButton(
                    text: "REGISTER",
                    isLoading: _isLoading,
                    onPressed: _handleSignUp,
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already a member?",
                        style: TextStyle(color: AppColors.textDim),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
