import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:petrofy/models/user_model.dart';
import 'package:petrofy/pages/admin/admin_profile_page.dart';
import 'package:petrofy/pages/admin/fuel_dashboard.dart';
import 'package:petrofy/pages/pumper/my_schedule_page.dart';
import 'package:petrofy/pages/reports/reporting_hub_page.dart';
import 'package:petrofy/pages/ai_dashboard_screen.dart';
import 'package:petrofy/pages/pumper/add_sale_page.dart';
import 'package:petrofy/pages/pumper/pumper_profile_page.dart';
import 'package:petrofy/pages/pumper/shift_view_page.dart';
import 'package:petrofy/pages/shop/customer_profile_page.dart';
import 'package:petrofy/pages/shop/lubricant_store_page.dart';
import '../utils/app_colors.dart';

class MainNavigationShell extends StatefulWidget {
  final String userRole;
  final String? initialTab; // ← receives tab name from notification tap

  const MainNavigationShell({
    super.key,
    required this.userRole,
    this.initialTab,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  late PageController _pageController;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    // Set starting tab based on notification tap, else default to 0
    _currentIndex = _resolveInitialTab();
    _pageController = PageController(initialPage: _currentIndex);
    _fetchUserData();
  }

  // Maps notification screen name → tab index for each role
  int _resolveInitialTab() {
    if (widget.initialTab == null) return 0;

    if (widget.userRole == 'pumper') {
      switch (widget.initialTab) {
        case 'shifts':    return 2; // Shifts tab index for pumper
        case 'sales':     return 1;
        default:          return 0;
      }
    }

    if (widget.userRole == 'admin' || widget.userRole == 'manager') {
      switch (widget.initialTab) {
        case 'shifts':    return 0; // managers see shifts in Stock/dashboard
        case 'sales':     return 0;
        default:          return 0;
      }
    }

    if (widget.initialTab == 'shop') return 0;

    return 0;
  }

  @override
  void didUpdateWidget(MainNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If a new notification arrives while app is open, jump to that tab
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      final newIndex = _resolveInitialTab();
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex = newIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _fetchUserData() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _currentUser =
              UserModel.fromMap(doc.data() as Map<String, dynamic>);
        });
      }
    }
  }

  List<Widget> _buildPages() {
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
          DashboardScreen(),
          ReportingHubPage(),
          AdminProfilePage(user: _currentUser!),
        ];
      case 'pumper':
        return [
          const FuelLevelDashboard(),
          const AddSalePage(),
          MySchedulePage(user: _currentUser!),
          PumperProfilePage(user: _currentUser!),
        ];
      default:
        return [
          LubricantStorePage(),
          const FuelLevelDashboard(),
          CustomerProfilePage(user: _currentUser!),
        ];
    }
  }

  List<GButton> _buildNavButtons() {
    if (widget.userRole == 'admin' || widget.userRole == 'manager') {
      return const [
        GButton(icon: Icons.local_gas_station_outlined, text: 'Stock'),
        GButton(icon: Icons.insights, text: 'AI'),
        GButton(icon: Icons.bar_chart_outlined, text: 'Insights'),
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
                  tabBackgroundColor:
                      AppColors.primaryGreen.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
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