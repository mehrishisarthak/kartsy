import 'dart:io';

import 'package:ecommerce_shop/utils/database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecommerce_shop/widget/support_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _productDescriptionController = TextEditingController();
    _productPriceController = TextEditingController();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productDescriptionController.dispose();
    _productPriceController.dispose();
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
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _uploadItem() async {
    if (selectedImage == null ||
        _productNameController.text.trim().isEmpty ||
        _productDescriptionController.text.trim().isEmpty ||
        _productPriceController.text.trim().isEmpty ||
        selectedCategory == null) {
      _showSnackBar('Please fill all the details and select an image.', isError: true);
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
        // FIX: Changed "adminID" to "adminId" for consistency
        "adminId": widget.adminID,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Add Product", style: AppWidget.boldTextStyle().copyWith(fontSize: 24, color: Colors.blue)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Upload Product Image", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _getImage,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(selectedImage!, fit: BoxFit.cover),
                          )
                        : const Center(child: Icon(Icons.camera_alt, size: 50, color: Colors.blue)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              Text("Product Name", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(controller: _productNameController, decoration: _inputDecoration('Product Name')),
              
              const SizedBox(height: 20),
              Text("Product Description", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(controller: _productDescriptionController, maxLines: 4, decoration: _inputDecoration('Product Description')),

              const SizedBox(height: 20),
              Text("Product Price (INR)", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(controller: _productPriceController, keyboardType: TextInputType.number, decoration: _inputDecoration('Price', prefixIcon: Icons.currency_rupee)),

              const SizedBox(height: 20),
              Text("Product Category", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: isLoading ? Container() : const Icon(Icons.add, color: Colors.white),
            label: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Add Product",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.blue) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2.0),
      ),
    );
  }
}
