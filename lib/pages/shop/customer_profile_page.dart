import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petrofy/home_page.dart';
import 'package:petrofy/pages/shop/my_orders_page.dart';
import 'package:petrofy/services/cloudinary_service.dart';
import 'package:petrofy/widgets/custom_components.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';

class CustomerProfilePage extends StatefulWidget {
  final UserModel user;
  const CustomerProfilePage({super.key, required this.user});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  bool _isUploading = false;
  late String _displayImage;

  @override
  void initState() {
    super.initState();
    _displayImage = widget.user.profilePic;
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
                  _buildCustomerHeader(),
                  const SizedBox(height: 20),

                  // --- CUSTOMER LOYALTY STATS ---
                  //  _buildSectionLabel("MY REWARDS"),
                  //   const SizedBox(height: 15),
                  // _buildLoyaltyStats(),
                  //  const SizedBox(height: 30),

                  // --- SHOPPING & ACTIVITY ---
                  _buildSectionLabel("SHOPPING ACTIVITY"),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    "Track Active Orders",
                    "Real-time status of your current shipments",
                    Icons.local_shipping_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyOrdersPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    "My Order History",
                    "View your past lubricant orders and receipts",
                    Icons.history_rounded,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyOrdersPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 5),

                  // --- ACCOUNT SETTINGS ---
                  _buildSectionLabel("ACCOUNT SETTINGS"),
                  const SizedBox(height: 15),

                  _buildMenuButton(
                    "Update Profile Image",
                    "Update administrative profile and security photo",
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

  // --- LOGIC ---
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
        showCustomSnackBar(context, "Profile Photo Updated");
      }
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _comingSoon(String title) {
    showCustomSnackBar(context, "$title Module Coming Soon");
  }

  // --- UI COMPONENTS (MATCHED TO ADMIN THEME) ---

  Widget _buildCustomerHeader() {
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

  Widget _buildLoyaltyStats() {
    return Row(
      children: [
        _buildStatTile("PETROFY POINTS", "1,240 Pts", Icons.stars_rounded),
        const SizedBox(width: 15),
        _buildStatTile(
          "MEMBERSHIP",
          "GOLD TIER",
          Icons.workspace_premium_rounded,
        ),
      ],
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
        child: _isUploading
            ? const CircularProgressIndicator(color: AppColors.primaryGreen)
            : null,
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
