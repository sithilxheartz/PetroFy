import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/fuel_sale_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/sales_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -100, left: -50, child: _buildGlow(300)),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(25, 60, 25, 20),
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
                      const SizedBox(height: 25),
                      _buildStatsRow(),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Text(
                    "TRANSACTION LOG",
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              StreamBuilder<List<FuelSaleModel>>(
                stream: _salesService.getPumperSales(widget.user.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Text("Syncing with Cloud Database..."),
                      ),
                    );
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    );
                  }

                  final sales = snapshot.data ?? [];
                  if (sales.isEmpty)
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          "No transactions yet",
                          style: TextStyle(color: AppColors.textDim),
                        ),
                      ),
                    );

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildHistoryCard(sales[index]),
                      childCount: sales.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
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
          ),
        ),
        if (_isUploading)
          const CircularProgressIndicator(color: AppColors.primaryGreen),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _handleImageUpload,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sync, color: Colors.black, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("ROLE", widget.user.role.toUpperCase()),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildStatItem("ID", widget.user.uid.substring(0, 6)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String val) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textDim, fontSize: 10),
        ),
        Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(FuelSaleModel sale) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
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
            child: const Icon(
              Icons.receipt_long,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.fuelType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('dd MMM | hh:mm a').format(sale.dateTime),
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "LKR ${sale.soldTotalPrice.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${sale.soldQuantity}L",
                style: const TextStyle(fontSize: 10, color: AppColors.textDim),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen.withOpacity(0.05),
      ),
    );
  }
}
