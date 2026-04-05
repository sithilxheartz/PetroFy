import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/lubricant_model.dart';
import '../../services/lubricant_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class LubricantGRNPage extends StatefulWidget {
  const LubricantGRNPage({super.key});

  @override
  State<LubricantGRNPage> createState() => _LubricantGRNPageState();
}

class _LubricantGRNPageState extends State<LubricantGRNPage> {
  final LubricantService _service = LubricantService();
  final _qtyController = TextEditingController();
  final _searchController = TextEditingController();

  String _searchQuery = "";
  LubricantModel? _selectedProduct;
  bool _isProcessing = false;

  void _confirmGRN() {
    if (_selectedProduct == null || _qtyController.text.isEmpty) {
      showCustomSnackBar(
        context,
        "Select a product and enter quantity",
        isError: true,
      );
      return;
    }

    int addedQty = int.tryParse(_qtyController.text) ?? 0;

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white10),
          ),
          title: const Text(
            "Confirm Stock Intake",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Add $addedQty units to ${_selectedProduct!.name}?\nNew Total: ${_selectedProduct!.stockQuantity + addedQty}",
            style: const TextStyle(color: AppColors.textDim),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CANCEL",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              onPressed: () {
                Navigator.pop(context);
                _processGRN(addedQty);
              },
              child: const Text(
                "CONFIRM GRN",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processGRN(int qty) async {
    setState(() => _isProcessing = true);
    try {
      await _service.updateStockQuantity(_selectedProduct!.id!, qty);
      showCustomSnackBar(
        context,
        "Stock updated for ${_selectedProduct!.name}",
      );
      _qtyController.clear();
      _searchController.clear();
      setState(() {
        _selectedProduct = null;
        _searchQuery = "";
      });
    } catch (e) {
      showCustomSnackBar(context, "Error: $e", isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
    extendBodyBehindAppBar:
          true, // Allows content to scroll under the blurred AppBar
      appBar: AppBar(
        title: const Text(
          "STORE INVENTORY INTAKE",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
            fontSize: 21,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
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
            child: Column(
              children: [
                // 1. Search Bar
                Padding(
                  padding: const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search product to add stock...",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primaryGreen,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
            
                // 2. Search Results / Selected Product
                Expanded(
                  child: _selectedProduct != null
                      ? _buildSelectedView()
                      : _buildSearchResults(),
                ),
            
                // 3. Footer Action (Only shown when product is selected)
                if (_selectedProduct != null)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: FuelButton(
                      text: "PROCESS STOCK INTAKE",
                      isLoading: _isProcessing,
                      onPressed: _confirmGRN,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<LubricantModel>>(
      stream: _service.getProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );

        final results = snapshot.data!
            .where(
              (p) =>
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  p.brand.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

        if (_searchQuery.isEmpty)
          return const Center(
            child: Text(
              "Type to search lubricants",
              style: TextStyle(color: AppColors.textDim),
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final p = results[index];
            return ListTile(
              onTap: () => setState(() => _selectedProduct = p),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  p.imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                p.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                "${p.brand} • ${p.size}",
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primaryGreen,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _selectedProduct!.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedProduct!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Current Stock: ${_selectedProduct!.stockQuantity}",
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => setState(() => _selectedProduct = null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "NEW STOCK QUANTITY",
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FuelNumberField(
            controller: _qtyController,
            label: "Enter items received",
            icon: Icons.inventory_2_outlined,
          ),
        ],
      ),
    );
  }
}
