import 'dart:convert';
import 'dart:io';
import 'package:ecommerce_shop/utils/database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // 1. NEW IMPORT
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:shimmer/shimmer.dart';

//TODO: change categories as per your needs
//TODO: ensure Firebase rules are set to allow uploads only by authenticated admins
//TODO: seperate this logic to new app for admins only


// --- MODEL VALIDATOR CLASS ---
class ModelValidator {
  static Future<bool> isDracoCompressed(File file) async {
    try {
      final filename = file.path.toLowerCase();
      if (!filename.endsWith('.glb') && !filename.endsWith('.gltf')) {
        return false;
      }
      final bytes = await file.openRead(0, 50 * 1024).first; 
      final content = utf8.decode(bytes, allowMalformed: true);
      const dracoKey = 'KHR_draco_mesh_compression';
      return content.contains(dracoKey);
    } catch (e) {
      print("Error validating model: $e");
      return false;
    }
  }
}

class AddProduct extends StatefulWidget {
  final String adminID;
  const AddProduct({super.key, required this.adminID});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final ImagePicker _picker = ImagePicker();
  
  List<File> selectedImages = [];
  
  // 3D Model State
  File? _selectedModelFile;
  String? _modelFileName;
  String? _modelFileSize;

  bool isLoading = false;
  String? selectedCategory;
  bool _agreedToTerms = false;

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

  // --- 2. UPDATED IMAGE PICKER WITH COMPRESSION ---
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        List<File> processedImages = [];

        for (var i in images) {
          // Strict check: don't allow selecting more than 5 total
          if ((selectedImages.length + processedImages.length) >= 5) {
            _showSnackBar("Maximum 5 images allowed.", isError: true);
            break;
          }

          File originalFile = File(i.path);
          int sizeInBytes = await originalFile.length();
          double sizeInMB = sizeInBytes / (1024 * 1024);

          // COMPRESSION LOGIC
          // Only compress if image is larger than 1MB
          if (sizeInMB > 1.0) {
            final String targetPath = '${originalFile.parent.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
            
            var result = await FlutterImageCompress.compressAndGetFile(
              originalFile.absolute.path,
              targetPath,
              quality: 70, // Good balance for e-commerce
              minWidth: 1080, 
              minHeight: 1080,
            );

            if (result != null) {
              processedImages.add(File(result.path));
            } else {
              // Fallback to original if compression fails
              processedImages.add(originalFile);
            }
          } else {
            // File is small enough, use original
            processedImages.add(originalFile);
          }
        }

        // Update UI
        setState(() {
          selectedImages.addAll(processedImages);
        });
      }
    } catch (e) {
      _showSnackBar("Image selection failed: $e", isError: true);
    }
  }

  Future<void> _pick3DModel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['glb', 'gltf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        int sizeInBytes = await file.length();
        double sizeInMB = sizeInBytes / (1024 * 1024);

        if (sizeInMB > 5.0) {
          _showSnackBar("File too large (${sizeInMB.toStringAsFixed(1)} MB). Limit is 5MB.", isError: true);
          return; 
        }

        bool isDraco = await ModelValidator.isDracoCompressed(file);
        if (!isDraco) {
           _showSnackBar("Invalid Model: File must be Draco compressed.", isError: true);
           return;
        }

        setState(() {
          _selectedModelFile = file;
          _modelFileName = result.files.single.name;
          _modelFileSize = "${sizeInMB.toStringAsFixed(2)} MB";
        });
        
        _showSnackBar("Model selected successfully!");
      }
    } catch (e) {
      _showSnackBar("Model selection failed: $e", isError: true);
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

    if (!_agreedToTerms) {
      _showSnackBar('You must agree to the terms.', isError: true);
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
      String? modelUrl;

      final storageRef = FirebaseStorage.instance.ref();

      // Upload Images
      for (int i = 0; i < selectedImages.length; i++) {
         final imageRef = storageRef.child('products/$productId/image_$i.jpg');
         await imageRef.putFile(selectedImages[i]);
         final url = await imageRef.getDownloadURL();
         imageUrls.add(url);
      }

      // Upload 3D Model
      if (_selectedModelFile != null) {
        final modelRef = storageRef.child('products/$productId/model.glb');
        await modelRef.putFile(_selectedModelFile!);
        modelUrl = await modelRef.getDownloadURL();
      }

      // Firestore Write
      final Map<String, dynamic> productData = {
        "id": productId,
        "Name": _productNameController.text.trim(),
        "Image": imageUrls.first, 
        "images": imageUrls, 
        "Description": _productDescriptionController.text.trim(),
        "Price": int.tryParse(_productPriceController.text.trim()) ?? 0,
        "adminId": widget.adminID,
        "inventory": inventory,
        "category": selectedCategory,
        if (modelUrl != null) "modelUrl": modelUrl, 
        "averageRating": 0.0,
        "reviewCount": 0,
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

  // --- Helper to build Shimmer Overlay ---
  Widget _buildLoadingOverlay(Widget child) {
    if (!isLoading) return child;
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
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
        title: Text("Add Product", style: textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Upload Product Images (Max 5)", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // --- IMAGES SECTION WITH SHIMMER ---
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (selectedImages.length < 5 && !isLoading)
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
                      
                      Widget imageContent = Stack(
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
                          if (!isLoading)
                            Positioned(
                              top: 5, right: 15,
                              child: GestureDetector(
                                onTap: () => setState(() => selectedImages.removeAt(idx)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                        ],
                      );

                      return isLoading ? _buildLoadingOverlay(Container(width: 120, height: 120, margin: const EdgeInsets.only(right: 10))) : imageContent;
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- 3D MODEL PICKER WITH SHIMMER ---
              Text("Upload 3D Model (Optional, < 5MB)", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              isLoading 
              ? _buildLoadingOverlay(SizedBox(height: 70, width: double.infinity))
              : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.view_in_ar, color: colorScheme.primary),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _modelFileName ?? "No model selected (.glb)",
                            style: TextStyle(
                              color: _modelFileName != null ? Colors.black : Colors.grey,
                              fontWeight: _modelFileName != null ? FontWeight.bold : FontWeight.normal
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          if (_modelFileSize != null)
                            Text(_modelFileSize!, style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (_selectedModelFile != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() {
                          _selectedModelFile = null;
                          _modelFileName = null;
                          _modelFileSize = null;
                        }),
                      )
                    else
                      ElevatedButton(
                        onPressed: _pick3DModel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                          elevation: 0,
                        ),
                        child: const Text("Pick File"),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              Text("Product Name", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(controller: _productNameController, enabled: !isLoading, decoration: const InputDecoration(hintText: 'Product Name')),

              const SizedBox(height: 20),
              Text("Product Description", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(controller: _productDescriptionController, enabled: !isLoading, maxLines: 4, decoration: const InputDecoration(hintText: 'Product Description')),

              const SizedBox(height: 20),
              Text("Product Inventory", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _productInventoryController,
                keyboardType: TextInputType.number,
                enabled: !isLoading,
                decoration: const InputDecoration(hintText: 'Product Inventory'),
              ),

              const SizedBox(height: 20),
              Text("Product Price (INR)", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(controller: _productPriceController, enabled: !isLoading, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Price', prefixIcon: Icon(Icons.currency_rupee))),

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
                    onChanged: isLoading ? null : (String? newValue) => setState(() => selectedCategory = newValue),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              CheckboxListTile(
                title: const Text("I certify that I have the right to sell this product."),
                value: _agreedToTerms,
                onChanged: isLoading ? null : (val) => setState(() => _agreedToTerms = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: colorScheme.primary,
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
                ? const Text("Uploading...") 
                : const Text("Add Product"),
          ),
        ),
      ),
    );
  }
}