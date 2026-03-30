import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/custom_components.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  void _updateRole(String userId, String newRole) {
    usersCollection.doc(userId).update({'role': newRole});
    showCustomSnackBar(context, "Role updated to ${newRole.toUpperCase()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("USER MANAGEMENT",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Glow
          Positioned(top: -50, left: -50, child: _buildGlow()),
          
          StreamBuilder<QuerySnapshot>(
            stream: usersCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Sync Error"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));

              final users = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  String currentRole = user['role'] ?? 'customer';
                  String email = user['email'] ?? 'No Email';
                  String name = "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}";

                  return _buildUserCard(user.id, name, email, currentRole);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(String id, String name, String email, String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getColorForRole(role).withOpacity(0.2),
            radius: 25,
            child: Text(
              role[0].toUpperCase(),
              style: TextStyle(color: _getColorForRole(role), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.trim().isEmpty ? "Unknown User" : name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(email, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
              ],
            ),
          ),
          _buildRoleDropdown(id, role),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown(String userId, String currentRole) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentRole,
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.edit, size: 14, color: AppColors.primaryGreen),
          items: ['customer', 'pumper', 'manager', 'admin'].map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (newRole) {
            if (newRole != null && newRole != currentRole) {
              _updateRole(userId, newRole);
            }
          },
        ),
      ),
    );
  }

  Color _getColorForRole(String role) {
    switch (role) {
      case 'admin': return Colors.redAccent;
      case 'manager': return Colors.purpleAccent;
      case 'pumper': return AppColors.primaryGreen;
      default: return Colors.blueAccent;
    }
  }

  Widget _buildGlow() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen.withOpacity(0.05),
      ),
    );
  }
}