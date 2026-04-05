import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petrofy/home_page.dart';
import 'package:petrofy/pages/admin/add_lubricant_page.dart';
import 'package:petrofy/pages/admin/admin_lubricant_list_page.dart';
import 'package:petrofy/pages/admin/lubricant_grn_page.dart';
import 'package:petrofy/pages/admin/payment_approval_page.dart';
import 'package:petrofy/pages/admin/price_config_page.dart';
import 'package:petrofy/pages/admin/user_control_page.dart';
import 'package:petrofy/services/cloudinary_service.dart';
import 'package:petrofy/widgets/custom_components.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';

class AdminProfilePage extends StatefulWidget {
  final UserModel user;
  const AdminProfilePage({super.key, required this.user});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  bool _isUploading = false;
  late String _displayImage;

  @override
  void initState() {
    super.initState();
    _displayImage = widget.user.profilePic;
  }

  // Generic navigator for your dummy buttons
  void _navigateToPage(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(title),
            backgroundColor: AppColors.surface,
          ),
          body: Center(
            child: Text(
              "$title Module Coming Soon",
              style: const TextStyle(color: Colors.white60, fontSize: 21),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Welcome Back, ${widget.user.firstName}!",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
        actions: [LogoutButton(), const SizedBox(width: 10)],
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildGlow()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: Column(
                children: [
                  _buildAdminHeader(),
                  const SizedBox(height: 20),
                  // STATION OVERVIEW STATS
                  //   _buildSectionLabel("STATION OVERVIEW"),
                  //  const SizedBox(height: 15),
                  // _buildLiveStationStats(),

                  // const SizedBox(height: 15),

                  // SYSTEM MANAGEMENT MENU
                  _buildSectionLabel("STATION MANAGEMENT"),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    "Sales Payment Approval",
                    "Verify and safe-keep pumper fuel payments",
                    Icons.fact_check_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentApprovalPage(
                            adminUser: widget.user,
                          ), // 👈 Passing the admin data
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    "Fuel Price Configuration",
                    "Update LKR rates for fuel types",
                    Icons.app_registration_rounded,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PriceConfigPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    "Store Inventory Control",
                    "Manage store lubricants prices and details",
                    Icons.storage_rounded,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminLubricantListPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    "Store Inventory Intake",
                    "Update lubricants' quantity levels with new stock",
                    Icons.add_business_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LubricantGRNPage(),
                        ),
                      );
                    },
                  ),

                  //    _buildMenuButton(
                  //      "Shift Scheduling",
                  //      "Assign staff to specific pumps",
                  //      Icons.calendar_month_rounded,
                  //      () => _navigateToPage("Shifts"),
                  //   ),
                  const SizedBox(height: 5),
                  _buildSectionLabel("SYSTEM MANAGEMENT"),
                  const SizedBox(height: 15),

                  _buildMenuButton(
                    "User Management",
                    "Control access for pumpers & managers",
                    Icons.people_alt_rounded,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserManagementPage(),
                        ),
                      );
                    },
                  ),
                                    _buildMenuButton(
                    "Update Profile Image",
                    "Sync your identification photo",
                    Icons.cloud_upload_outlined,
                    _handleImageUpload, // Connected to image upload logic
                  ),
                  // _buildMenuButton(
                  //    "System Settings",
                  //   "Configure cloud sync & notifications",
                  //    Icons.settings_suggest_rounded,
                  //    () => _navigateToPage("Settings"),
                  //   ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- IMAGE UPLOAD LOGIC ---
  Future<void> _handleImageUpload() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image != null && mounted) {
      setState(() => _isUploading = true);
      String? url = await CloudinaryService().uploadProfileImage(image);

      if (url != null && mounted) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update({'profilePic': url});
        setState(() => _displayImage = url);
        showCustomSnackBar(context, "Cloud Sync Complete");
      }
      if (mounted) setState(() => _isUploading = false);
    }
  }
  // --- UI COMPONENTS ---

  Widget _buildAdminHeader() {
    return Column(
      children: [
        _buildAvatarSection(),
        const SizedBox(height: 15),
        Text(
          "${widget.user.firstName} ${widget.user.lastName}",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          widget.user.email,
          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLiveStationStats() {
    return StreamBuilder<DocumentSnapshot>(
      // Pulling the daily summary you requested earlier
      stream: FirebaseFirestore.instance
          .collection('fuelSaleHistory')
          .doc(DateTime.now().toString().substring(0, 10))
          .snapshots(),
      builder: (context, snapshot) {
        return Row(
          children: [
            _buildStatTile(
              "STATION REVENUE",
              "LKR XXX,XXX",
              Icons.payments_rounded,
            ),
            const SizedBox(width: 15),
            _buildStatTile(
              "TANK STATUS",
              "XX% Healthy",
              Icons.ev_station_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String val, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              val,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    String title,
    String sub,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white12,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryGreen, width: 2),
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(_displayImage),
        backgroundColor: AppColors.surface,
      ),
    );
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
