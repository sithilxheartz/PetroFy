import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:petrofy/pages/admin/add_lubricant_page.dart';
import '../../models/lubricant_model.dart';
import '../../services/lubricant_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class AdminLubricantListPage extends StatefulWidget {
  const AdminLubricantListPage({super.key});

  @override
  State<AdminLubricantListPage> createState() => _AdminLubricantListPageState();
}

class _AdminLubricantListPageState extends State<AdminLubricantListPage> {
  final LubricantService _service = LubricantService();
  
  // --- NEW: SEARCH STATE ---
  String _searchQuery = "";

  // --- 1. THE THEMED EDIT BOTTOM SHEET ---
  void _showEditSheet(LubricantModel product) {
    final nameController = TextEditingController(text: product.name);
    final brandController = TextEditingController(text: product.brand);
    final descController = TextEditingController(text: product.description);
    final buyPriceController = TextEditingController(text: product.buyingPrice.toStringAsFixed(0));
    final sellPriceController = TextEditingController(text: product.sellingPrice.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "EDIT PRODUCT DETAILS",
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.primaryGreen,
                      fontSize: 14,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      _buildThemedField(nameController, "Product Name", Icons.edit_outlined),
                      _buildThemedField(brandController, "Brand", Icons.branding_watermark_outlined),
                      _buildThemedField(descController, "Description", Icons.notes, maxLines: 1),
                      Row(
                        children: [
                          Expanded(child: _buildThemedField(buyPriceController, "Buying Price", Icons.arrow_downward, isNum: true)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildThemedField(sellPriceController, "Selling Price", Icons.arrow_upward, isNum: true)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FuelButton(
                        text: "UPDATE PRODUCT",
                        onPressed: () => _confirmSave(context, product.id!, {
                          'name': nameController.text.trim(),
                          'brand': brandController.text.trim(),
                          'description': descController.text.trim(),
                          'buyingPrice': double.tryParse(buyPriceController.text) ?? 0,
                          'sellingPrice': double.tryParse(sellPriceController.text) ?? 0,
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. SEARCH BAR WIDGET ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10, top: 15),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
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

  // --- 3. CONFIRMATION DIALOGS ---
  void _confirmSave(BuildContext context, String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
          title: const Text("Confirm Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text("Save these changes to the live store?", style: TextStyle(color: AppColors.textDim)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              onPressed: () async {
                await _service.updateProduct(id, data);
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  showCustomSnackBar(context, "Product Successfully Updated");
                }
              },
              child: const Text("CONFIRM", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LubricantModel product) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent, width: 0.5)),
          title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.redAccent), SizedBox(width: 10), Text("Delete Item", style: TextStyle(color: Colors.white))]),
          content: Text("Delete ${product.name} permanently?", style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                await _service.deleteProduct(product.id!);
                if (mounted) {
                  Navigator.pop(context);
                  showCustomSnackBar(context, "${product.name} removed", isError: true);
                }
              },
              child: const Text("DELETE", style: TextStyle(color: Colors.white)),
            ),
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
        title: const Text("PRODUCT INVENTORY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15, top: 8, bottom: 8),
            child: SizedBox(
              width: 135,
              child: TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddLubricantPage())),
                icon: const Icon(Icons.add_business_outlined, color: Colors.white, size: 18),
                label: const Text("NEW ITEM", style: TextStyle(color: Colors.white, fontSize: 12)),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.1), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen.withOpacity(0.05)))),
          Positioned(bottom: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen.withOpacity(0.05)))),
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(), // --- INTEGRATED SEARCH BAR ---
                Expanded(
                  child: StreamBuilder<List<LubricantModel>>(
                    stream: _service.getProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                      
                      // Filter products based on search query locally
                      final products = snapshot.data!.where((p) {
                        return p.name.toLowerCase().contains(_searchQuery) || 
                               p.brand.toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (products.isEmpty) {
                        return const Center(child: Text("No products found", style: TextStyle(color: AppColors.textDim)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        itemCount: products.length,
                        itemBuilder: (context, index) => _buildAdminProductTile(products[index]),
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

  Widget _buildAdminProductTile(LubricantModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(product.imageUrl, width: 55, height: 55, fit: BoxFit.cover)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                Text("${product.brand} • ${product.size}", style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                Text("Stock: ${product.stockQuantity}", style: const TextStyle(color: AppColors.primaryGreen, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primaryGreen, size: 22),
            onPressed: () => _showEditSheet(product),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 22),
            onPressed: () => _confirmDelete(context, product),
          ),
        ],
      ),
    );
  }

  Widget _buildThemedField(TextEditingController controller, String label, IconData icon, {bool isNum = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: GoogleFonts.poppins().fontFamily),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: GoogleFonts.poppins().fontFamily),
          prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 18),
          filled: true,
          fillColor: AppColors.surface.withOpacity(0.3),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primaryGreen)),
        ),
      ),
    );
  }
}