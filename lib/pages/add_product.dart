import 'dart:io';

import 'package:ecommerce_shop/utils/database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';

class AddProduct extends StatefulWidget {
  final String adminID;
  const AddProduct({super.key, required this.adminID});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  bool isLoading = false;
  String? selectedCategory;

  late TextEditingController _productNameController;
  late TextEditingController _productDescriptionController;
  late TextEditingController _productPriceController;
  late TextEditingController _productInventoryController;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _productDescriptionController = TextEditingController();
    _productPriceController = TextEditingController();
    _productInventoryController = TextEditingController();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productDescriptionController.dispose();
    _productPriceController.dispose();
    _productInventoryController.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar("Image selection failed: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  Future<void> _uploadItem() async {
    // Basic validation for empty fields and image
    if (selectedImage == null ||
        _productNameController.text.trim().isEmpty ||
        _productDescriptionController.text.trim().isEmpty ||
        _productPriceController.text.trim().isEmpty ||
        _productInventoryController.text.trim().isEmpty ||
        selectedCategory == null) {
      _showSnackBar('Please fill all the details and select an image.', isError: true);
      return;
    }
    
    // --- New inventory validation check ---
    final int? inventory = int.tryParse(_productInventoryController.text.trim());
    
    if (inventory == null || inventory < 10) {
      _showSnackBar('Product inventory must be 10 or more.', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final String productId = randomAlphaNumeric(10);
      final ref = FirebaseStorage.instance.ref().child('products/$productId.jpg');
      final uploadTask = await ref.putFile(selectedImage!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final Map<String, dynamic> productData = {
        "id": productId,
        "Name": _productNameController.text.trim(),
        "Image": downloadUrl,
        "Description": _productDescriptionController.text.trim(),
        "Price": int.tryParse(_productPriceController.text.trim()) ?? 0,
        "adminId": widget.adminID,
        "inventory": inventory
      };

      await DatabaseMethods().addProduct(productData, selectedCategory!, widget.adminID);

      _showSnackBar('$selectedCategory added successfully!');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("An unexpected error occurred: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Product",
          style: textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Upload Product Image", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _getImage,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.surface,
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(selectedImage!, fit: BoxFit.cover),
                          )
                        : Center(child: Icon(Icons.camera_alt, size: 50, color: colorScheme.primary)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              Text("Product Name", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(controller: _productNameController, decoration: const InputDecoration(hintText: 'Product Name')),
              
              const SizedBox(height: 20),
              Text("Product Description", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(controller: _productDescriptionController, maxLines: 4, decoration: const InputDecoration(hintText: 'Product Description')),

              const SizedBox(height: 20),
              Text("Product Inventory", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _productInventoryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Product Inventory'),
              ),

              const SizedBox(height: 20),
              Text("Product Price (INR)", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(controller: _productPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Price', prefixIcon: Icon(Icons.currency_rupee))),

              const SizedBox(height: 20),
              Text("Product Category", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: Theme.of(context).inputDecorationTheme.enabledBorder!.borderSide.color),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    hint: const Text('Select Category'),
                    isExpanded: true,
                    items: <String>['Watch', 'Laptop', 'TV', 'Headphones']
                        .map((String category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (String? newValue) => setState(() => selectedCategory = newValue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 55,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _uploadItem,
            icon: isLoading ? Container() : const Icon(Icons.add),
            label: isLoading
                ? const CircularProgressIndicator()
                : const Text("Add Product"),
          ),
        ),
      ),
    );
  }
}