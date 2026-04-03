import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/lubricant_model.dart';
import '../../services/lubricant_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class LubricantStorePage extends StatefulWidget {
  const LubricantStorePage({super.key});

  @override
  State<LubricantStorePage> createState() => _LubricantStorePageState();
}

class _LubricantStorePageState extends State<LubricantStorePage> {
  final LubricantService _service = LubricantService();
  String _searchQuery = "";

  // THIS IS THE POPUP FUNCTION
  void _showProductDetails(LubricantModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Image Header
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      child: Image.network(
                        product.imageUrl,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
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
                
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(product.brand.toUpperCase(), 
                            style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                            child: Text(product.size, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(product.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 15),
                      
                      const Text("Description", style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(product.description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                      
                      const SizedBox(height: 25),
                      
                      // Information Frosted Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            _buildPopupRow("Unit Price", "LKR ${product.sellingPrice.toStringAsFixed(2)}"),
                            const Divider(color: Colors.white10, height: 20),
                            _buildPopupRow("Stock Status", 
                              product.stockQuantity > 0 ? "In Stock (${product.stockQuantity})" : "Out of Stock",
                              valColor: product.stockQuantity > 0 ? AppColors.primaryGreen : Colors.redAccent),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      FuelButton(
                        text: "ADD TO CART", 
                        onPressed: () {
                          Navigator.pop(context);
                          showCustomSnackBar(context, "${product.name} added to cart!");
                        }
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupRow(String label, String value, {Color valColor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDim)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valColor, fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("LUBRICANT SHOP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Poppins')),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Glow
          Positioned(top: -50, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen.withOpacity(0.05)))),
          
          SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      hintText: "Search lubricants...",
                      hintStyle: const TextStyle(color: Colors.white38),
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
                      
                      final filtered = snapshot.data!.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildProductCard(filtered[index]),
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

  Widget _buildProductCard(LubricantModel product) {
    return GestureDetector(
      onTap: () => _showProductDetails(product),
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
                  Text(product.brand, style: const TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                  const SizedBox(height: 5),
                  Text("LKR ${product.sellingPrice.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}