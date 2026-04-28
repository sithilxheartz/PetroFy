import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petrofy/providers/cart_provider.dart';
import 'package:petrofy/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:petrofy/utils/app_colors.dart';
import 'package:petrofy/pages/main_navigation_shell.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages handled silently
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Stores which tab to open when notification is tapped
  String? _initialTabFromNotification;

  @override
  void initState() {
    super.initState();

    // App opened from terminated state by tapping notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message.data);
      }
    });

    // App was in background, notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data);
    });

    // Check if a foreground local notification was tapped
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screen = NotificationService.getPendingScreen();
      if (screen != null) _handleNotificationTap({'screen': screen});
    });
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final screen = data['screen'];

    if (screen == 'my_schedule' || screen == 'generate_schedule' ||
        screen == 'shifts') {
      // Small delay to ensure widget tree is ready
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          // 'shifts' tells MainNavigationShell to open the shifts tab
          _initialTabFromNotification = 'shifts';
        });
      });
    }

    if (screen == 'shop') {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _initialTabFromNotification = 'shop';
        });
      });
    }

    if (screen == 'sales') {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _initialTabFromNotification = 'sales';
        });
      });
    }
  }

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            );
          }

          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userDoc) {
                if (userDoc.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryGreen),
                    ),
                  );
                }

                String role = 'pumper';
                if (userDoc.hasData && userDoc.data!.exists) {
                  role = userDoc.data!.get('role');
                }

                return MainNavigationShell(
                  userRole: role,
                  // Pass the tab name from notification tap (null = default)
                  initialTab: _initialTabFromNotification,
                );
              },
            );
          }

          return const LoginPage();
        },
      ),
    );
  }
}