import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:petrofy/models/user_model.dart'; // Ensure this import exists
import 'package:petrofy/pages/admin/add_order_page.dart';
import 'package:petrofy/pages/admin/admin_profile_page.dart';
import 'package:petrofy/pages/admin/fuel_dashboard.dart';
import 'package:petrofy/pages/pumper/add_sale_page.dart';
import 'package:petrofy/pages/pumper/profile_page.dart';
import 'package:petrofy/pages/pumper/shift_view_page.dart';
import 'package:petrofy/pages/shop/lubricant_store_page.dart';
import '../utils/app_colors.dart';

class MainNavigationShell extends StatefulWidget {
  final String userRole;
  const MainNavigationShell({super.key, required this.userRole});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  late PageController _pageController;
  UserModel? _currentUser; // Holds the fetched user data

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fetchUserData(); // Fetch user data on startup
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fetch the logged-in user details from Firestore
  void _fetchUserData() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        });
      }
    }
  }

  // 1. Define Pages based on Role
  List<Widget> _buildPages() {
    // Show loading while user data is being fetched
    if (_currentUser == null) {
      return List.generate(
        4,
        (index) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    switch (widget.userRole) {
      case 'admin':
      case 'manager':
        return [
          const FuelLevelDashboard(),
          LubricantStorePage(),
          AddOrderPage(adminUser: _currentUser!),
          AdminProfilePage(user: _currentUser!), // Pass actual user
        ];
      case 'pumper':
        return [
          const FuelLevelDashboard(),
          const AddSalePage(),
          ShiftViewPage(user: _currentUser!), // Pass actual user
          PumperProfilePage(user: _currentUser!),
        ];
      default:
        return [
          LubricantStorePage(),
          const FuelLevelDashboard(),
          const Center(child: Text("Coming Soon...")),
          PumperProfilePage(user: _currentUser!),
        ];
    }
  }

  // 2. Define Animated GNav Buttons
  List<GButton> _buildNavButtons() {
    if (widget.userRole == 'admin' || widget.userRole == 'manager') {
      return const [
        GButton(icon: Icons.local_gas_station_outlined, text: 'Stock'),
        GButton(icon: Icons.bar_chart_outlined, text: 'Insights'),
        GButton(icon: Icons.add_business_outlined, text: 'Order'),
        GButton(icon: Icons.person_outline, text: 'Profile'),
      ];
    } else if (widget.userRole == 'pumper') {
      return const [
        GButton(icon: Icons.local_gas_station_outlined, text: 'Stock'),
        GButton(icon: Icons.add_shopping_cart_outlined, text: 'Sales'),
        GButton(icon: Icons.history_outlined, text: 'Shifts'),
        GButton(icon: Icons.person_outline, text: 'Profile'),
      ];
    } else {
      return const [
        GButton(icon: Icons.store, text: 'Store'),
        GButton(icon: Icons.local_gas_station_outlined, text: 'Fuel'),
        GButton(icon: Icons.newspaper, text: 'News'),
        GButton(icon: Icons.person_outline, text: 'Profile'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _buildPages(),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.2),
              width: 1.5,
            ),
            //    boxShadow: [
            //    BoxShadow(
            //      color: AppColors.primaryGreen.withOpacity(0.1),
            //      blurRadius: 20,
            //      spreadRadius: 2,
            //    ),
            //   ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GNav(
                  haptic: true,
                  tabBorderRadius: 20,
                  curve: Curves.easeOutExpo,
                  duration: const Duration(milliseconds: 400),
                  gap: 8,
                  color: AppColors.textDim,
                  activeColor: AppColors.primaryGreen,
                  iconSize: 24,
                  tabBackgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  selectedIndex: _currentIndex,
                  onTabChange: (index) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  tabs: _buildNavButtons(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
