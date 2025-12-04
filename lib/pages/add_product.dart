import 'dart:io';
import 'package:ecommerce_shop/utils/database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
// Removed file_picker import as we don't need it anymore

class AddProduct extends StatefulWidget {
  final String adminID;
  const AddProduct({super.key, required this.adminID});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final ImagePicker _picker = ImagePicker();
  
  // List to hold multiple images
  List<File> selectedImages = [];
  
  bool isLoading = false;
  String? selectedCategory;

  late TextEditingController _productNameController;
  late TextEditingController _productDescriptionController;
  late TextEditingController _productPriceController;
  late TextEditingController _productInventoryController;
  // CHANGED: Added controller for URL
  late TextEditingController _sketchfabUrlController;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _productDescriptionController = TextEditingController();
    _productPriceController = TextEditingController();
    _productInventoryController = TextEditingController();
    _sketchfabUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productDescriptionController.dispose();
    _productPriceController.dispose();
    _productInventoryController.dispose();
    _sketchfabUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (var i in images) {
             if (selectedImages.length < 5) {
               selectedImages.add(File(i.path));
             } else {
               _showSnackBar("Maximum 5 images allowed.", isError: true);
               break;
             }
          }
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
    if (selectedImages.isEmpty ||
        _productNameController.text.trim().isEmpty ||
        _productDescriptionController.text.trim().isEmpty ||
        _productPriceController.text.trim().isEmpty ||
        _productInventoryController.text.trim().isEmpty ||
        selectedCategory == null) {
      _showSnackBar('Please fill all details and select at least one image.', isError: true);
      return;
    }

    final int? inventory = int.tryParse(_productInventoryController.text.trim());
    if (inventory == null || inventory < 10) {
      _showSnackBar('Product inventory must be 10 or more.', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final String productId = randomAlphaNumeric(10);
      List<String> imageUrls = [];

      // 1. Upload Images Loop
      for (int i = 0; i < selectedImages.length; i++) {
         final imageRef = FirebaseStorage.instance
             .ref()
             .child('products/$productId/image_$i.jpg');
         final uploadTask = await imageRef.putFile(selectedImages[i]);
         final url = await uploadTask.ref.getDownloadURL();
         imageUrls.add(url);
      }

      // 2. Prepare Data Map
      // We no longer upload a 3D file, we just take the text string
      String sketchfabUrl = _sketchfabUrlController.text.trim();

      final Map<String, dynamic> productData = {
        "id": productId,
        "Name": _productNameController.text.trim(),
        "Image": imageUrls.first, 
        "images": imageUrls, 
        "Description": _productDescriptionController.text.trim(),
        "Price": int.tryParse(_productPriceController.text.trim()) ?? 0,
        "adminId": widget.adminID,
        "inventory": inventory,
        // Save the URL if the user typed one
        if (sketchfabUrl.isNotEmpty) "sketchfabUrl": sketchfabUrl,
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
              Text("Upload Product Images (Max 5)", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // Horizontal Image List
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (selectedImages.length < 5)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.primary, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                            color: colorScheme.surface,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: colorScheme.primary),
                              const SizedBox(height: 5),
                              Text("${selectedImages.length}/5", style: TextStyle(color: colorScheme.primary))
                            ],
                          ),
                        ),
                      ),

                    ...selectedImages.asMap().entries.map((entry) {
                      int idx = entry.key;
                      File file = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: Colors.grey.shade300)
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(file, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 15,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImages.removeAt(idx);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // CHANGED: Replaced Custom File Picker with Simple TextField
              Text("Sketchfab URL (Optional)", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _sketchfabUrlController, 
                decoration: const InputDecoration(
                  hintText: 'Paste 3D Model URL here',
                  prefixIcon: Icon(Icons.link)
                ),
              ),
              // ---------------------------------------------------------

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