import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _searchController = TextEditingController();
  
  String _searchQuery = "";
  bool _isProcessing = false;

  // Key: Product ID, Value: Map containing product data and its own controller
  final Map<String, Map<String, dynamic>> _grnQueue = {};

  void _addToQueue(LubricantModel product) {
    if (_grnQueue.containsKey(product.id)) {
      showCustomSnackBar(context, "${product.name} is already in the list", isError: true);
      return;
    }
    setState(() {
      _grnQueue[product.id!] = {
        'product': product,
        'controller': TextEditingController(text: "0"),
      };
      _searchController.clear();
      _searchQuery = "";
    });
  }

  Future<void> _processBulkGRN() async {
    setState(() => _isProcessing = true);
    try {
      for (var entry in _grnQueue.values) {
        LubricantModel p = entry['product'];
        int qty = int.tryParse(entry['controller'].text) ?? 0;
        if (qty > 0) {
          await _service.updateStockQuantity(p.id!, qty);
        }
      }
      showCustomSnackBar(context, "Inventory updated successfully");
      setState(() => _grnQueue.clear());
    } catch (e) {
      showCustomSnackBar(context, "Update failed: $e", isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Fix 1: Ensure the scaffold resizes when keyboard opens
      resizeToAvoidBottomInset: true, 
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "ADD NEW STOCKS (GRN)",
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
          _buildBackgroundCircles(),
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                // Search Results Overlay
                if (_searchQuery.isNotEmpty) 
                  _buildSearchResults(),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("ITEMS TO UPDATE STOCKS", 
                        style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                      Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 14),
                    ],
                  ),
                ),

                // Fix 2: Queue list is now the main scrolling area
                Expanded(child: _buildQueueList()),
              ],
            ),
          ),
        ],
      ),
      // Fix 3: Move action button to bottomNavigationBar to prevent Overflow
      bottomNavigationBar: _grnQueue.isNotEmpty 
        ? Container(
            padding: EdgeInsets.only(
              left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 15 : 35, top: 10
            ),
            color: AppColors.background,
            child: FuelButton(
              text: "CONFIRM ${_grnQueue.length} DELEVERIES",
              isLoading: _isProcessing,
              onPressed: () => _confirmBulkGRN(context),
            ),
          )
        : null,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
         style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search Products to Add...",
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

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
      ),
      child: StreamBuilder<List<LubricantModel>>(
        stream: _service.getProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator(color: AppColors.primaryGreen);
          
          final results = snapshot.data!.where((p) => 
            p.name.toLowerCase().contains(_searchQuery) || 
            p.brand.toLowerCase().contains(_searchQuery)
          ).toList();

          return ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final p = results[index];
              return ListTile(
                onTap: () => _addToQueue(p),
                leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(p.imageUrl, width: 35, height: 35, fit: BoxFit.cover)),
                title: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(p.brand, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                trailing: const Icon(Icons.add_circle, color: AppColors.primaryGreen, size: 22),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQueueList() {
    if (_grnQueue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add_rounded, size: 40, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 10),
            const Text("Your intake list is empty", style: TextStyle(color: Colors.white12, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: _grnQueue.values.map((entry) {
        LubricantModel p = entry['product'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
                           color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
       //   color: _getStatusColor(status).withOpacity(0.1),
          color: AppColors.primaryGreen.withOpacity(0.1),
          width: 1.5,
        ),
      ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("Current Stock: ${p.stockQuantity}", style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: entry['controller'],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: const InputDecoration(
                    suffixText: " units",
                    suffixStyle: TextStyle(fontSize: 10, color: Colors.white),
                    border: InputBorder.none,
                    hintText: "0",
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => setState(() => _grnQueue.remove(p.id)),
                child: const Icon(Icons.delete , color: Colors.redAccent, size: 20),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _confirmBulkGRN(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text("Confirm Batch Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text("Proceed with inventory intake for ${_grnQueue.length} items?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.red))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              onPressed: () { Navigator.pop(context); _processBulkGRN(); },
              child: const Text("CONFIRM", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundCircles() {
    return Stack(
      children: [
        Positioned(top: -50, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen.withOpacity(0.05)))),
        Positioned(bottom: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen.withOpacity(0.05)))),
      ],
    );
  }
}