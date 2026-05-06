import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_components.dart';
import 'signup_page.dart';
import 'main_navigation_shell.dart';
import '../models/user_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // ── NEW: Forgot Password Dialog ──────────────────────────────────────────
  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.primaryGreen.withOpacity(
                    0.1,
                  ), // your border color
                  width: 1.5, // adjust thickness
                ),
              ),
              title: const Column(
                children: [
                  Icon(
                    Icons.lock_reset,
                    color: AppColors.primaryGreen,
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Reset Password",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Enter your email to receive a reset link",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textDim),
                  ),
                ],
              ),
              content: FuelTextField(
                // reuses your existing styled widget
                controller: resetEmailController,
                label: "Email Address",
                icon: Icons.alternate_email,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.textDim),
                  ),
                ),
                FuelButton(
                  // reuses your existing styled button
                  text: "Send Link",
                  isLoading: isSending,
                  onPressed: () async {
                    final email = resetEmailController.text.trim();
                    if (email.isEmpty) {
                      showCustomSnackBar(
                        context,
                        "Please enter your email",
                        isError: true,
                      );
                      return;
                    }

                    setDialogState(() => isSending = true);
                    final error = await _authService.resetPassword(email);
                    setDialogState(() => isSending = false);

                    if (!mounted) return;
                    Navigator.pop(context); // close dialog first

                    if (error == null) {
                      showCustomSnackBar(
                        context,
                        "Reset link sent! Check your inbox.",
                        isError: false, // green success snackbar
                      );
                    } else {
                      showCustomSnackBar(context, error, isError: true);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  // ─────────────────────────────────────────────────────────────────────────

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showCustomSnackBar(
        context,
        "Please enter your credentials",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    UserModel? user = await _authService.signInUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigationShell(userRole: user.role),
        ),
      );
    } else {
      if (mounted)
        showCustomSnackBar(context, "Invalid Email or Password", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 80,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: 15),
                const Text(
                  "PETROFY",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const Text(
                  "Intelligent Fuel Management",
                  style: TextStyle(color: AppColors.textDim, fontSize: 14),
                ),
                const SizedBox(height: 40),
                FuelTextField(
                  controller: _emailController,
                  label: "Email Address",
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 10),
                FuelTextField(
                  controller: _passwordController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog, // ← WIRED UP
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: AppColors.textDim),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                FuelButton(
                  text: "AUTHENTICATE",
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: AppColors.textDim),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupPage(),
                        ),
                      ),
                      child: const Text(
                        "Register Now",
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
    );
  }
}
