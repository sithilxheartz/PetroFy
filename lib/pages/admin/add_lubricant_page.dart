import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/lubricant_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/lubricant_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class AddLubricantPage extends StatefulWidget {
  const AddLubricantPage({super.key});

  @override
  State<AddLubricantPage> createState() => _AddLubricantPageState();
}

class _AddLubricantPageState extends State<AddLubricantPage> {
  final _formKey = GlobalKey<FormState>();
  final LubricantService _service = LubricantService();
  final CloudinaryService _cloudinary = CloudinaryService();

  // Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _brandController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;

  // Changed from List<String> to a single String
  String? _selectedSize;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  // Updated to set a single value instead of toggling a list
  void _selectSize(String size) {
    setState(() {
      _selectedSize = size;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() ||
        _selectedImage == null ||
        _selectedSize == null) {
      showCustomSnackBar(
        context,
        _selectedImage == null
            ? "Product image is required"
            : _selectedSize == null
            ? "Please select a size"
            : "All fields are required",
        isError: true,
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      // 1. Upload to Cloudinary
      String? imageUrl = await _cloudinary.uploadProfileImage(
        XFile(_selectedImage!.path),
      );

      if (imageUrl != null) {
        // 2. Save to Firestore
        LubricantModel product = LubricantModel(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          brand: _brandController.text.trim(),
          buyingPrice: double.parse(_buyPriceController.text),
          sellingPrice: double.parse(_sellPriceController.text),
          imageUrl: imageUrl,
          // Sending the single string size
          sizes: [_selectedSize!],
          stockQuantity: int.parse(_stockController.text),
        );

        await _service.addProduct(product);
        if (mounted) {
          showCustomSnackBar(context, "Product Added Successfully");
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) showCustomSnackBar(context, "Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "ADD NEW PRODUCT",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: AppColors.background.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildGlow()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 5),
                    _buildSectionLabel("BASIC INFORMATIONS"),
                    SizedBox(height: 5),
                    _buildField(_nameController, "Product Name", Icons.edit),
                    _buildField(
                      _brandController,
                      "Brand",
                      Icons.branding_watermark,
                    ),
                    _buildField(
                      _descController,
                      "Description",
                      Icons.description,
                      maxLines: 1,
                    ),
                    _buildSectionLabel("PRICING INFORMATIONS"),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            _buyPriceController,
                            "Buying Price",
                            Icons.input,
                            isNum: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildField(
                            _sellPriceController,
                            "Selling Price",
                            Icons.payments,
                            isNum: true,
                          ),
                        ),
                      ],
                    ),
                    _buildField(
                      _stockController,
                      "Initial Stock Quantity",
                      Icons.inventory_2,
                      isNum: true,
                    ),

                    _buildSectionLabel("AVAILABLE SIZE"),
                    _buildSizePicker(),
                    const SizedBox(height: 20),
                    FuelButton(
                      text: "SAVE PRODUCT",
                      isLoading: _isUploading,
                      onPressed: _handleSave,
                    ),
                                  //    const SizedBox(height: 300),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 130,
          width: 130,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
            image: _selectedImage != null
                ? DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _selectedImage == null
              ? const Icon(
                  Icons.add_a_photo,
                  color: AppColors.primaryGreen,
                  size: 40,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNum = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 18),
          filled: true,
          fillColor: AppColors.surface.withOpacity(0.3),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primaryGreen),
          ),
        ),
      ),
    );
  }

  Widget _buildSizePicker() {
    List<String> options = ["1", "250ml", "500ml", "750ml", "1L", "4L", "5L"];
    return Wrap(
      spacing: 10,
      children: options.map((size) {
        // Selection check against the single string
        bool isSelected = _selectedSize == size;
        return FilterChip(
          label: Text(size),
          selected: isSelected,
          // Force single selection logic
          onSelected: (bool selected) {
            _selectSize(size);
          },
          selectedColor: AppColors.primaryGreen,
          checkmarkColor: Colors.black,
          labelStyle: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12,
          ),
          backgroundColor: AppColors.surface,
        );
      }).toList(),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 0, top: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildGlow() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen.withOpacity(0.05),
      ),
    );
  }
}
