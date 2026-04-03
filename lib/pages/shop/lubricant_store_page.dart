import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item_model.dart';
import '../../models/lubricant_model.dart';
import '../../services/lubricant_service.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';
import 'cart_page.dart';

class LubricantStorePage extends StatefulWidget {
  const LubricantStorePage({super.key});

  @override
  State<LubricantStorePage> createState() => _LubricantStorePageState();
}

class _LubricantStorePageState extends State<LubricantStorePage> {
  final LubricantService _service = LubricantService();
  String _searchQuery = "";

  // --- THE PRODUCT DETAILS POPUP ---
  void _showProductDetails(LubricantModel product, CartProvider cartProv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            children: [
              // 1. Top Handle & Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    child: Image.network(
                      product.imageUrl,
                      height: 320,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Close Button
                  Positioned(
                    top: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              
              // 2. Product Info Section
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(product.brand.toUpperCase(), 
                            style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 11)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                            child: Text(product.size, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(product.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
                      const SizedBox(height: 15),
                      
                      const Text("PRODUCT DESCRIPTION", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(product.description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
                      
                      const SizedBox(height: 25),
                      
                      // Price & Stock Stats Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow("Market Price", "LKR ${product.sellingPrice.toStringAsFixed(2)}"),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.white10, thickness: 1),
                            ),
                            _buildInfoRow(
                              "Inventory Status", 
                              product.stockQuantity > 0 ? "AVAILABLE" : "OUT OF STOCK",
                              valColor: product.stockQuantity > 0 ? AppColors.primaryGreen : Colors.redAccent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // 3. Bottom Action Bar
              Padding(
                padding: const EdgeInsets.all(25),
                child: FuelButton(
                  text: "ADD TO MY CART", 
                  onPressed: () {
                    cartProv.addProduct(product); // Correctly using the Firestore method
                    Navigator.pop(context);
                    showCustomSnackBar(context, "${product.name} added to your account cart!");
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color valColor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valColor, fontSize: 15, fontFamily: 'Poppins')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // We only need the reference to call addProduct, not to listen to changes here
    final cartProv = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("PETROFY STORE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Poppins')),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
        actions: [
          // Shopping Cart Badge
          StreamBuilder<List<CartItemModel>>(
            stream: cartProv.cartItemsStream,
            builder: (context, snapshot) {
              int count = snapshot.data?.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
                      icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8, top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(10)),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text('$count', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                ),
              );
            }
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen.withOpacity(0.05)))),
          SafeArea(
            child: Column(
              children: [
                // Modern Search Bar
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      hintText: "Search by brand or product...",
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),

                Expanded(
                  child: StreamBuilder<List<LubricantModel>>(
                    stream: _service.getProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                      
                      final filtered = snapshot.data!.where((p) => 
                        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        p.brand.toLowerCase().contains(_searchQuery.toLowerCase())
                      ).toList();

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildProductCard(filtered[index], cartProv),
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

  Widget _buildProductCard(LubricantModel product, CartProvider cartProv) {
    return GestureDetector(
      onTap: () => _showProductDetails(product, cartProv),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                child: Image.network(product.imageUrl, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.brand, style: const TextStyle(color: AppColors.primaryGreen, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins')),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("LKR ${product.sellingPrice.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                      const Icon(Icons.arrow_forward_ios, color: AppColors.primaryGreen, size: 12),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}