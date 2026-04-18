import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for persistence
import 'package:cloud_firestore/cloud_firestore.dart'; // Added to fetch roles
import 'package:petrofy/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:petrofy/utils/app_colors.dart';
import 'package:petrofy/pages/main_navigation_shell.dart'; // Added
import 'firebase_options.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: AppColors.textMain,
          displayColor: AppColors.textMain,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: AppColors.textDim),
          hintStyle: TextStyle(color: AppColors.textDim),
        ),
      ),
      // --- UPDATED HOME LOGIC FOR PERSISTENCE ---
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If Firebase is checking the token, show a loader
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
            );
          }

          // If a user exists in the stream, they are already logged in
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userDoc) {
                if (userDoc.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)));
                }
                
                // Fetch the role from Firestore to load the correct Shell
                String role = 'pumper'; // Default fallback
                if (userDoc.hasData && userDoc.data!.exists) {
                  role = userDoc.data!.get('role');
                }
                
                return MainNavigationShell(userRole: role);
              },
            );
          }

          // No user found? Go to Login Page
          return const LoginPage();
        },
      ),
    );
  }
}