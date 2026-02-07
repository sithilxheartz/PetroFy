import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';

class CustomerHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Customer Home"), actions: [LogoutButton()]),
      body: Center(child: Text("Welcome, valued Customer!", style: TextStyle(fontSize: 20))),
    );
  }
}

class PumperHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pumper Station"), backgroundColor: Colors.orange, actions: [LogoutButton()]),
      body: Center(child: Text("Pumper Interface", style: TextStyle(fontSize: 20))),
    );
  }
}

class ManagerHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manager Dashboard"), backgroundColor: Colors.purple, actions: [LogoutButton()]),
      body: Center(child: Text("Manager Controls", style: TextStyle(fontSize: 20))),
    );
  }
}

// A helper button to logout from any screen
class LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.logout),
      onPressed: () {
        AuthService().signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      },
    );
  }
}