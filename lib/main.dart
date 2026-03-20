import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:petrofy/utils/app_colors.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Petrofy AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryGreen,
        // This ensures all text uses White by default
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: AppColors.textMain,
          displayColor: AppColors.textMain,
        ),
      ),
      home: const LoginPage(),
    );
  }
}