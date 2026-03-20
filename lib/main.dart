import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:petrofy/utils/app_colors.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with your generated options
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
        
        // 1. Set Poppins as the primary font family for the whole app
        fontFamily: GoogleFonts.poppins().fontFamily,

        // 2. Apply Poppins to all text styles (Headlines, Body, etc.)
        // This ensures consistent coloring and font weight across the app
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: AppColors.textMain,
          displayColor: AppColors.textMain,
        ),

        // 3. Optional: Style your input decoration globally to match Poppins
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: AppColors.textDim),
          hintStyle: TextStyle(color: AppColors.textDim),
        ),
      ),
      home: const LoginPage(),
    );
  }
}