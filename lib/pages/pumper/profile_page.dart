import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petrofy/home_page.dart';
import '../../models/user_model.dart';
import '../../models/fuel_sale_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/sales_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';
import 'profile_popups.dart';

class PumperProfilePage extends StatefulWidget {
  final UserModel user;
  const PumperProfilePage({super.key, required this.user});

  @override
  State<PumperProfilePage> createState() => _PumperProfilePageState();
}

class _PumperProfilePageState extends State<PumperProfilePage> {
  final SalesService _salesService = SalesService();
  bool _isUploading = false;
  late String _displayImage;

  @override
  void initState() {
    super.initState();
    _displayImage = widget.user.profilePic;
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

  // --- POPUP TRIGGER ---
  void _showPopup(String title, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 15),
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.primaryGreen,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: child),
          ],
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 23,
            letterSpacing: 0,
          ),
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
                  _buildAvatarSection(),
                  const SizedBox(height: 15),
                  Text(
                    "${widget.user.firstName} ${widget.user.lastName}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.user.email,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
            
                  // TODAY'S QUICK STATS
                  StreamBuilder<List<FuelSaleModel>>(
                    stream: _salesService.getPumperFilteredSales(
                      widget.user.uid,
                      DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ),
                    ),
                    builder: (context, snapshot) {
                      final sales = snapshot.data ?? [];
                      double vol = sales.fold(
                        0,
                        (sum, item) => sum + item.soldQuantity,
                      );
                      return Row(
                        children: [
                          _buildStatTile(
                            "TODAY'S SALES",
                            "${vol.toStringAsFixed(1)}0L",
                            Icons.speed,
                          ),
                          const SizedBox(width: 15),
                          _buildStatTile(
                            "USER ROLE",
                            widget.user.role.substring(0, 6).toUpperCase(),
                            Icons.badge_outlined,
                          ),
                        ],
                      );
                    },
                  ),
            
                  const SizedBox(height: 15),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "OPERATIONAL MENU",
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
            
                  _buildMenuButton(
                    "Sales History",
                    "Track your daily dispense logs",
                    Icons.history,
                    () => _showPopup(
                      "SALES HISTORY",
                      SalesHistoryPopup(pumperId: widget.user.uid),
                    ),
                  ),
                  _buildMenuButton(
                    "Duty History",
                    "Review assigned shifts and pumps",
                    Icons.assignment_turned_in_outlined,
                    () => _showPopup(
                      "DUTY HISTORY",
                      ShiftHistoryPopup(pumperId: widget.user.uid),
                    ),
                  ),
                  _buildMenuButton(
                    "Update Profile Image",
                    "Sync your identification photo",
                    Icons.cloud_upload_outlined,
                    _handleImageUpload, // Connected to image upload logic
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String val, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 25),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3,),
            Text(
              val,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryGreen, width: 2),
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundImage: NetworkImage(_displayImage),
            backgroundColor: AppColors.surface,
          ),
        ),
        if (_isUploading)
          const CircularProgressIndicator(color: AppColors.primaryGreen),
      ],
    );
  }

  Widget _buildGlow() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen.withOpacity(0.03),
      ),
    );
  }
}
