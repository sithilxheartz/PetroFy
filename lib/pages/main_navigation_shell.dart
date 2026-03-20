import 'package:flutter/material.dart';
import 'package:petrofy/pages/user_control_page.dart';
import '../utils/app_colors.dart';
// Import your pages here...

class MainNavigationShell extends StatefulWidget {
  final String userRole;
  const MainNavigationShell({required this.userRole});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  // This function decides which pages to show based on the role
  List<Widget> _buildPages() {
    switch (widget.userRole) {
      case 'admin':
      case 'manager':
        return [AdminDashboard(), AdminDashboard(), AdminDashboard()];
      case 'pumper':
        return [AdminDashboard(), AdminDashboard(), AdminDashboard()];
      default: // customer
        return [AdminDashboard(), AdminDashboard(), AdminDashboard()];
    }
  }

  // This function decides which icons to show in the Bottom Bar
  List<BottomNavigationBarItem> _buildNavItems() {
    if (widget.userRole == 'admin' || widget.userRole == 'manager') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        BottomNavigationBarItem(icon: Icon(Icons.ev_station), label: 'Tanks'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'AI Prediction'),
      ];
    } else if (widget.userRole == 'pumper') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.local_gas_station), label: 'Pump'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Queue'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Find Fuel'),
        BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'My Car'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack( // Keeps page state alive
        index: _currentIndex,
        children: _buildPages(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textDim,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        items: _buildNavItems(),
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}