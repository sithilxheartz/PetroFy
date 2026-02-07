import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_page.dart'; // Import for the Logout button

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  // Function to update the role in Firestore
  void _updateRole(String userId, String newRole) {
    usersCollection.doc(userId).update({'role': newRole});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Role updated to $newRole"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel"),
        backgroundColor: Colors.redAccent,
        actions: [LogoutButton()],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersCollection.snapshots(), // Listen to real-time changes
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Something went wrong"));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              String currentRole = user['role'];
              String email = user['email'];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorForRole(currentRole),
                    child: Text(currentRole[0].toUpperCase(), style: TextStyle(color: Colors.white)),
                  ),
                  title: Text(email, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Current Role: $currentRole"),
                  trailing: DropdownButton<String>(
                    value: currentRole,
                    underline: Container(), // Remove underline
                    icon: Icon(Icons.edit, color: Colors.blue),
                    items: ['customer', 'pumper', 'manager', 'admin'].map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role.toUpperCase(), style: TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (String? newRole) {
                      if (newRole != null && newRole != currentRole) {
                        _updateRole(user.id, newRole);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper to color-code roles
  Color _getColorForRole(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'manager': return Colors.purple;
      case 'pumper': return Colors.orange;
      case 'customer': return Colors.blue;
      default: return Colors.grey;
    }
  }
}