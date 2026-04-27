import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/lubricant_model.dart';
import '../../models/review_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/review_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class ProductDetailsSheet extends StatefulWidget {
  final LubricantModel product;
  final CartProvider cartProv;

  const ProductDetailsSheet({
    super.key,
    required this.product,
    required this.cartProv,
  });

  @override
  State<ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<ProductDetailsSheet> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _reviewController = TextEditingController();
  double _userRating = 5.0;

  // --- UPDATED SUBMIT REVIEW ---
  void _submitReview() async {
    if (_reviewController.text.isEmpty) return;

    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        // Fetch User details from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        String finalName = "Customer";

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          String fName = data['firstName'] ?? "";
          String lName = data['lastName'] ?? "";
          finalName = "$fName $lName".trim();
        }

        // If Firestore name is empty, fallback to email prefix
        if (finalName.isEmpty) {
          finalName = firebaseUser.email?.split('@')[0] ?? "Customer";
        }

        final newReview = ReviewModel(
          id: '',
          fullName: finalName,
          comment: _reviewController.text.trim(),
          rating: _userRating,
          timestamp: DateTime.now(),
        );

        await _reviewService.addReview(widget.product.id!, newReview);

        _reviewController.clear();
        if (mounted) {
          setState(() => _userRating = 5.0);
          showCustomSnackBar(
            context,
            "Review posted as $finalName!",
            isError: false,
          );
        }
      } catch (e) {
        showCustomSnackBar(context, "Error: $e", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            _buildImageHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductTitleSection(),
                    const SizedBox(height: 10),
                    _buildInventoryPriceCards(),
                    const SizedBox(height: 15),
                    const Text(
                      "PRODUCT SPECIFICATIONS",
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.product.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Colors.white10),
                    ),

                    // --- MODERN REVIEW FORM ---
                    _buildInteractiveReviewForm(),

                    const SizedBox(height: 20),
                    const Text(
                      "CUSTOMER FEEDBACK",
                      style: TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildReviewList(),
                                 const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
            _buildStickyFooter(),
          ],
        ),
      ),
    );
  }

  // UI Component: Image Header
  Widget _buildImageHeader() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: Image.network(
            widget.product.imageUrl,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const CircleAvatar(
              backgroundColor: Colors.black45,
              child: Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  // UI Component: Title & Brand
  Widget _buildProductTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.product.brand.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.product.size,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          widget.product.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // UI Component: Stock & Price Grid
  Widget _buildInventoryPriceCards() {
    return Row(
      children: [
        _infoTile(
          "Current Stock",
          "${widget.product.stockQuantity} Units",
          Icons.inventory_2_outlined,
        ),
        const SizedBox(width: 15),
        _infoTile(
          "Selling Price",
          "Rs.${widget.product.sellingPrice.toInt()}",
          Icons.payments_outlined,
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 18),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(color: AppColors.textDim, fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI Component: Modern Review Entry
  Widget _buildInteractiveReviewForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Post a Review",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
              (index) => GestureDetector(
                onTap: () => setState(() => _userRating = index + 1.0),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    index < _userRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reviewController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Tell others what you think...",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: AppColors.primaryGreen,
                ),
                onPressed: _submitReview,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI Component: Real-time Review Feed
  Widget _buildReviewList() {
    return StreamBuilder<List<ReviewModel>>(
      stream: _reviewService.getReviews(widget.product.id!),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const LinearProgressIndicator(color: AppColors.primaryGreen);
        final reviews = snapshot.data!;
        if (reviews.isEmpty)
          return const Text(
            "No reviews found. Be the first to rate!",
            style: TextStyle(color: AppColors.textDim, fontSize: 12),
          );

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final rev = reviews[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.surface,
                    radius: 18,
                    child: Text(
                      rev.fullName.isNotEmpty
                          ? rev.fullName[0].toUpperCase()
                          : "U",
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rev.fullName, // Changed from rev.userName
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star,
                                  size: 10,
                                  color: i < rev.rating
                                      ? AppColors.primaryGreen
                                      : Colors.white10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          rev.comment,
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // UI Component: Bottom Action
  Widget _buildStickyFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 15, 25, 35),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: FuelButton(
        text: "ADD TO CART + Rs.${widget.product.sellingPrice.toInt()}",
        onPressed: () {
          widget.cartProv.addProduct(widget.product);
          // Pop first so SnackBar shows on the Store Page
          Navigator.pop(context);
          showCustomSnackBar(
            context,
            "${widget.product.name} added to cart!",
            isError: false,
          );
        },
      ),
    );
  }
}
