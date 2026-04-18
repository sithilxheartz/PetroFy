import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item_model.dart';
import '../../models/lubricant_model.dart';
import '../../services/lubricant_service.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_colors.dart';
import 'cart_page.dart';
import 'product_details_sheet.dart'; // Ensure this matches your new file name

class LubricantStorePage extends StatefulWidget {
  const LubricantStorePage({super.key});

  @override
  State<LubricantStorePage> createState() => _LubricantStorePageState();
}

class _LubricantStorePageState extends State<LubricantStorePage> {
  final LubricantService _service = LubricantService();
  String _searchQuery = "";

  // This opens the externalized details sheet
  void _openDetails(LubricantModel product, CartProvider cartProv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ProductDetailsSheet(product: product, cartProv: cartProv),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProv = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "PETROFY STORE",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
        actions: [_buildCartBadge(cartProv)],
      ),
      body: Stack(
        children: [
          _buildBackgroundGlow(),
          Column(
            children: [
              // Padding for the transparent AppBar
              const SizedBox(height: kToolbarHeight + 30),

              _buildSearchBar(),

              Expanded(
                child: StreamBuilder<List<LubricantModel>>(
                  stream: _service.getProducts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      );
                    }

                    final filtered = snapshot.data!
                        .where(
                          (p) =>
                              p.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              p.brand.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                        )
                        .toList();

                    return GridView.builder(
                      // Bottom padding (140) allows items to scroll above your floating GNav bar
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(filtered[index], cartProv),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15, top: 15),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
                hintText: "Search by Name or Brand...",
          hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
          filled: true,
          fillColor: AppColors.surface,
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

  Widget _buildProductCard(LubricantModel product, CartProvider cartProv) {
    return GestureDetector(
      onTap: () => _openDetails(product, cartProv),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: AppColors.primaryGreen.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                child: Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white24),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rs.${product.sellingPrice.toInt()}",
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white24,
                        size: 10,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBadge(CartProvider cartProv) {
    return StreamBuilder<List<CartItemModel>>(
      stream: cartProv.cartItemsStream,
      builder: (context, snapshot) {
        int count = snapshot.data?.length ?? 0;
        return Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                ),
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
              ),
              if (count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -50,
      right: -50,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryGreen.withOpacity(0.05),
        ),
      ),
    );
  }
}
