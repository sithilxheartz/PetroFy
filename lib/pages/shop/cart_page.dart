import 'dart:ui';
import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text("YOUR CART", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
      ),
      body: StreamBuilder<List<CartItemModel>>(
        stream: cartProv.cartItemsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          
          final items = snapshot.data ?? [];
          if (items.isEmpty) return _buildEmptyCart();

          double total = items.fold(0, (sum, item) => sum + (item.price * item.quantity));

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _buildCartTile(items[index], cartProv),
                ),
              ),
              _buildCheckoutFooter(total),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartTile(CartItemModel item, CartProvider prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("${item.size} | Qty: ${item.quantity}", style: const TextStyle(color: AppColors.primaryGreen, fontSize: 11)),
            ]),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("LKR ${(item.price * item.quantity).toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => prov.deleteItem(item.productId)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCheckoutFooter(double total) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Total Payable", style: TextStyle(color: AppColors.textDim)),
              Text("LKR ${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            ]),
            const SizedBox(height: 20),
            FuelButton(text: "CHECKOUT NOW", onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() => const Center(child: Text("Cart is Empty", style: TextStyle(fontFamily: 'Poppins', color: AppColors.textDim)));
}