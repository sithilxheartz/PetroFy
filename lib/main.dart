import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

void main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  // If you didn't use FlutterFire CLI, remove 'options: DefaultFirebaseOptions.currentPlatform'
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Run the App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Role Based Auth',
      theme: ThemeData(
        fontFamily: GoogleFonts.poppins().fontFamily,
        brightness: Brightness.dark,
      ),
      // 4. Set the initial route to Login
      home: LoginPage(),
      
      // Optional: If you want to use named routes instead of Navigator.push
      // routes: {
      //   '/login': (context) => LoginPage(),
      //   '/signup': (context) => SignupPage(),
      //   '/admin': (context) => AdminDashboard(),
      // },
    );
  }
}