import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecommerce_shop/widget/support_widget.dart';
import 'package:provider/provider.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> productData;
  const ProductDetails({super.key, required this.productData});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool _isLoading = false;

  /// Handles adding the product to the cart, managed by the CartProvider.
  Future<void> _handleAddToCart() async {
    setState(() => _isLoading = true);

    try {
      final userId = await SharedPreferenceHelper().getUserID();
      if (userId == null || userId.isEmpty) {
        throw Exception('User ID not found.');
      }

      // Let the provider handle both local state and database operations
      // ignore: use_build_context_synchronously
      await Provider.of<CartProvider>(context, listen: false)
          .addToCart(userId, widget.productData);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product added to cart successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint("Error adding to cart: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding to cart: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.productData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),

      // --- AppBar ---
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
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
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
                        'Product',
                        style: AppWidget.boldTextStyle().copyWith(
                          fontSize: 30,
                          color: Colors.blue,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // To balance the back button space
                ],
              ),
            ),
          ),
        ),
      ),

      // --- Body ---
      body: Column(
        children: [
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              product['Image'] ?? '',
              height: 260,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 80),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        product['Name'] ?? 'No Name',
                        style: AppWidget.boldTextStyle().copyWith(
                          fontSize: 28,
                          color: Colors.black87,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 10),
                      // Price
                      Text(
                        '₹${product['Price'] ?? '--'}',
                        style: AppWidget.boldTextStyle().copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Details heading
                      Text(
                        'Details',
                        style: GoogleFonts.lato(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Description
                      Text(
                        product['Description'] ??
                            "No description provided for this product.",
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // --- Bottom Button ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 55,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleAddToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Add to Cart",
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
