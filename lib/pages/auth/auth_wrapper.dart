import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petrofy/pages/login_page.dart';
import 'package:petrofy/pages/main_navigation_shell.dart';
import '../../utils/app_colors.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. If the connection is still loading, show a splash/loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
          );
        }

        // 2. If the snapshot has user data, they are logged in!
        if (snapshot.hasData) {
          // You might need to fetch the role from Firestore here if your shell needs it.
          // For now, we assume a default role or handle it inside the shell.
          return const MainNavigationShell(userRole: 'pumper'); 
        }

        // 3. Otherwise, show the Login Page
        return const LoginPage();
      },
    );
  }
}