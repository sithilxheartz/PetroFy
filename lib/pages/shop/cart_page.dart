import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProv = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "SHOPPING CART",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15, top: 8, bottom: 8),
            child: Container(
              width: 155,
              height: 35,
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "MY ORDERS",
                  style: TextStyle(
                    color: Colors.white,
                    //   fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
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
          ),
          SafeArea(
            child: StreamBuilder<List<CartItemModel>>(
              stream: cartProv.cartItemsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  );
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) return _buildEmptyCart();

                double total = items.fold(
                  0,
                  (sum, item) => sum + (item.price * item.quantity),
                );

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            _buildCartTile(items[index], cartProv),
                      ),
                    ),
                    _buildCheckoutFooter(total),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartTile(CartItemModel item, CartProvider prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1), width: 1.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              item.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "${item.size} | Qty: ${item.quantity}",
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5.0, right: 5),
                child: Text(
                  "LKR ${(item.price * item.quantity).toInt()}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 23,
                ),
                onPressed: () => prov.deleteItem(item.productId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutFooter(double total) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "TOTAL PAYABLE:",
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
                Text(
                  "LKR ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FuelButton(text: "CHECKOUT NOW", onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() => const Center(
    child: Text(
      "Cart is Empty",
      style: TextStyle(fontFamily: 'Poppins', color: AppColors.textDim),
    ),
  );
}
