import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petrofy/home_page.dart';
import 'package:petrofy/pages/admin/add_order_page.dart';
import 'package:petrofy/pages/admin/admin_lubricant_list_page.dart';
import 'package:petrofy/pages/admin/send_notification_page.dart';
import 'package:petrofy/pages/reports/fuel_orders_report_page.dart';
import 'package:petrofy/pages/reports/fuel_sales_reports_page.dart';
import 'package:petrofy/pages/admin/lubricant_grn_page.dart';
import 'package:petrofy/pages/admin/manage_orders_page.dart';
import 'package:petrofy/pages/admin/payment_approval_page.dart';
import 'package:petrofy/pages/admin/price_config_page.dart';
import 'package:petrofy/pages/admin/user_control_page.dart';
import 'package:petrofy/pages/reports/shift_report_page.dart';
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                children: [
                  _buildAdminHeader(),
                  const SizedBox(height: 20),

                  _buildSectionLabel("REPORTS & INSIGHTS"),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    "Fuel Sales Report",
                    "Configure real-time LKR pricing for fuel types",
                      Icons.bar_chart_rounded,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FuelReportsPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    "Fuel Orders Report",
                    "Configure real-time LKR pricing for fuel types",
                      Icons.bar_chart_rounded,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FuelOrdersReportPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    "Shift Roster Report",
                    "Configure real-time LKR pricing for fuel types",
                      Icons.bar_chart_rounded,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShiftReportPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 5),
                  _buildSectionLabel("STATION OPERATIONS"),
                  const SizedBox(height: 15),

                  _buildMenuButton(
                    "Sales Payment Approval",
                    "Review pumper fuel shift payments",
                    Icons.fact_check_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PaymentApprovalPage(adminUser: widget.user),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    "Add New Fuel Stock (GRN)",
                    "Register incoming new fuel orders",
                    Icons.add_business_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddOrderPage(adminUser: widget.user),
                        ),
                      );
                    },
                  ),

                  _buildMenuButton(
                    "Fuel Rate Control",
                    "Configure real-time LKR pricing for fuel types",
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

                  const SizedBox(height: 5),

                  // --- INVENTORY & LOGISTICS ---
                  _buildSectionLabel("INVENTORY & LOGISTICS"),
                  const SizedBox(height: 15),

                  _buildMenuButton(
                    "Catalog Management",
                    "Modify lubricant specifications & pricing",
                    Icons.inventory_2_outlined,
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
                    "Add New Product Stocks (GRN)",
                    "Register incoming inventory stock levels",
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

                  _buildMenuButton(
                    "Pending Online Orders",
                    "Process active shipments & track deliveries",
                    Icons
                        .local_shipping_outlined, // Changed to a more suitable icon
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageOrdersPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 5),

                  // --- ADMINISTRATION ---
                  _buildSectionLabel("SYSTEM ADMINISTRATION"),
                  const SizedBox(height: 15),

                  _buildMenuButton(
                    "Send Broadcast Notification",
                    "Send Special notification for users",
                    Icons.notification_add,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SendNotificationPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    "User Access Control",
                    "Manage system permissions for users",
                    Icons.admin_panel_settings_outlined,
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
                    "Update administrative profile photo",
                    Icons.face_retouching_natural_rounded,
                    _handleImageUpload,
                  ),

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.1),
              width: 1.5,
            ),
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
