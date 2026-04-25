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
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Search Controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateRole(String userId, String newRole) {
    usersCollection.doc(userId).update({'role': newRole});
    showCustomSnackBar(context, "Role updated to ${newRole.toUpperCase()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "USER MANAGEMENT",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
            fontSize: 21,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildGlow()),
          Positioned(bottom: -50, left: -50, child: _buildGlow()),

          SafeArea(
            child: Column(
              children: [
                // Search Bar Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                  child: _buildSearchBar(),
                ),
            
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: usersCollection.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Center(child: Text("Sync Error"));
                      if (!snapshot.hasData)
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
            
                      // Filter Logic
                      final allUsers = snapshot.data!.docs;
                      final filteredUsers = allUsers.where((doc) {
                        String firstName = (doc['firstName'] ?? '')
                            .toString()
                            .toLowerCase();
                        String lastName = (doc['lastName'] ?? '')
                            .toString()
                            .toLowerCase();
                        String email = (doc['email'] ?? '')
                            .toString()
                            .toLowerCase();
                        String fullName = "$firstName $lastName";
            
                        return fullName.contains(_searchQuery.toLowerCase()) ||
                            email.contains(_searchQuery.toLowerCase());
                      }).toList();
            
                      if (filteredUsers.isEmpty) {
                        return const Center(
                          child: Text(
                            "No users found",
                            style: TextStyle(color: AppColors.textDim),
                          ),
                        );
                      }
            
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          String currentRole = user['role'] ?? 'customer';
                          String email = user['email'] ?? 'No Email';
                          String name =
                              "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}";
            
                          return _buildUserCard(
                            user.id,
                            name,
                            email,
                            currentRole,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildSearchBar() {
  return Padding(
    padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0, top: 0),
    child: TextField(
      controller: _searchController, // Keeps your controller functionality
      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Search by Name or Email...",
        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
        
        // --- Added the functionality back to the new theme ---
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textDim, size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = "";
                  });
                },
              )
            : null,
            
        // --- Themed visual styling ---
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: AppColors.primaryGreen.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 1.5,
          ),
        ),
      ),
    ),
  );
}

  Widget _buildUserCard(String id, String name, String email, String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
       //   color: _getStatusColor(status).withOpacity(0.1),
          color: AppColors.primaryGreen.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getColorForRole(role).withOpacity(0.2),
            radius: 25,
            child: Text(
              role[0].toUpperCase(),
              style: TextStyle(
                color: _getColorForRole(role),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.trim().isEmpty ? "Unknown User" : name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
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
              child: Text(
                role.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
      case 'admin':
        return Colors.redAccent;
      case 'manager':
        return Colors.purpleAccent;
      case 'pumper':
        return AppColors.primaryGreen;
      default:
        return Colors.blueAccent;
    }
  }

  Widget _buildGlow() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen.withOpacity(0.05),
      ),
    );
  }
}
