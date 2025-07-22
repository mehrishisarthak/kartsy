import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  // Removed invalid assignment; use widget.adminId directly.
  String? value;
  late TextEditingController _productName;
  late TextEditingController _productDescription;
  late TextEditingController _productPrice;

   Future<void> getImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image selection failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  bool isLoading = false;


  Future<void> uploadItem() async {
    if (selectedImage == null ||
        _productName.text.trim().isEmpty ||
        _productDescription.text.trim().isEmpty ||
        _productPrice.text.trim().isEmpty ||
        value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all the details and select an image.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final String addId = randomAlphaNumeric(10);
      final ref = FirebaseStorage.instance.ref().child('products/$addId.jpg');
      final uploadTask = await ref.putFile(selectedImage!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final Map<String, dynamic> addProduct = {
        "id" : addId,
        "Name": _productName.text.trim(),
        "Image": downloadUrl,
        "Description": _productDescription.text.trim(),
        "Price": int.parse(_productPrice.text.trim()),
        "adminID" : widget.adminID // Storing price as int
      };

      await DatabaseMethods().addProduct(addProduct, value!, widget.adminID);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$value added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: ${e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An unexpected error occurred: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _productName = TextEditingController();
    _productDescription = TextEditingController();
    _productPrice = TextEditingController();
  }

  @override
  void dispose() {
    _productName.dispose();
    _productDescription.dispose();
    _productPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.blue),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Add Product",
                        style: AppWidget.boldTextStyle().copyWith(
                          fontSize: 24,
                          color: Colors.blue,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Upload Product Image", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: getImage,
                    child: Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        image: selectedImage != null
                            ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: selectedImage == null
                          ? const Icon(Icons.camera_alt, size: 60, color: Colors.blue)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text("Choose Product Category", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      hint: const Text('Select Category'),
                      isExpanded: true,
                      items: <String>['Watch', 'Laptop', 'TV', 'Headphones']
                          .map((String category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (String? newValue) => setState(() => value = newValue),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text("Enter Product Name", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextField(
                  controller: _productName,
                  decoration: InputDecoration(
                    hintText: 'Product Name',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text("Enter Product Description", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextField(
                  maxLines: null,
                  controller: _productDescription,
                  decoration: InputDecoration(
                    hintText: 'Product Description',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text("Enter Product Price (INR)", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: _productPrice,
                  decoration: InputDecoration(
                    hintText: 'Price',
                    prefixIcon: const Icon(Icons.currency_rupee, color: Colors.blue),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: const [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 25,
        offset: Offset(0, -10), // this pushes shadow upward
      ),
    ],
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(30),
      topRight: Radius.circular(30),
    ),
  ),
  padding: const EdgeInsets.all(20),
  child: SizedBox(
    height: 55,
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : uploadItem,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              "Add Product",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
    ),
  ),
),

    );
  }
}
