import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:petrofy/pages/admin/add_tank_page.dart';
import 'package:petrofy/pages/admin/fuel_dashboard.dart';
import 'package:petrofy/pages/pumper/add_sale_page.dart';
import 'package:petrofy/pages/user_control_page.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 1. Define Pages based on Role
  List<Widget> _buildPages() {
    switch (widget.userRole) {
      case 'admin':
      case 'manager':
        return [
          const FuelLevelDashboard(), // Real-time Tank Status
          AdminDashboard(), // User Role Control
          const AddTankPage(), // Register New Hardware
          const Center(child: Text("AI Analytics Engine")),
        ];
      case 'pumper':
        return [
          const FuelLevelDashboard(), // Real-time Tank Status
          AdminDashboard(), // Real-time Tank Status
          const AddSalePage(), // Register New Hardware
          const Center(child: Text("AI Analytics Engine")),
        ];
      default: // customer
        return [
          const Center(child: Text("Customer Home")),
          const Center(child: Text("Fuel Stations")),
          const Center(child: Text("Vehicle Stats")),
        ];
    }
  }

  // 2. Define Animated GNav Buttons based on Role
  List<GButton> _buildNavButtons() {
    if (widget.userRole == 'admin' || widget.userRole == 'manager') {
      return const [
        GButton(icon: Icons.ev_station_outlined, text: 'Inventory'),
        GButton(icon: Icons.people_outline, text: 'Users'),
        GButton(icon: Icons.add_circle_outline, text: 'Register'),
        GButton(icon: Icons.analytics_outlined, text: 'AI Data'),
      ];
    } else if (widget.userRole == 'pumper') {
      return const [
        GButton(icon: Icons.ev_station_outlined, text: 'Inventory'),
        GButton(icon: Icons.ev_station_outlined, text: 'Inventory'),
        GButton(icon: Icons.add_circle_outline, text: 'Add Sale'),
        GButton(icon: Icons.analytics_outlined, text: 'AI Data'),
      ];
    } else {
      return const [
        GButton(icon: Icons.home_outlined, text: 'Home'),
        GButton(icon: Icons.map_outlined, text: 'Find'),
        GButton(icon: Icons.directions_car_filled_outlined, text: 'Cars'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // CRITICAL: Extends body behind the bottom bar for the "Float" effect
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
            color: AppColors.surface.withOpacity(0.8), // Semi-transparent black
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.2),
              width: 1.5,
            ),
        //    boxShadow: [
        //      BoxShadow(
          //      color: AppColors.primaryGreen.withOpacity(0.1),
            //    blurRadius: 20,
              //  spreadRadius: 2,
                //offset: const Offset(0, 5),
             // ),
           // ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ), // The Glass Frost
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
