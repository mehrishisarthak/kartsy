import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/utils/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AddReviewPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const AddReviewPage({super.key, required this.productData});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reviewController = TextEditingController();
  
  // Initialize rating to 0 to detect if user touched it
  double _rating = 0; 
  bool _isLoading = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 🚨 FIX: Ensure user selected a rating
    if (_rating == 0) {
      _showSnackBar("Please select a star rating.", isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _showSnackBar("Session expired. Please log in again.", isError: true);
        return;
      }
      
      final productId = widget.productData['id'];
      if (productId == null) throw Exception("Product ID is missing.");

      // Check existence using UserID as DocID (Fast & Secure)
      final reviewDocRef = FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(userId);

      if ((await reviewDocRef.get()).exists) {
        _showSnackBar("You have already reviewed this product.", isError: true);
        return;
      }

      // NOTE: Ensure DatabaseMethods().addReview also updates 
      // the product's 'averageRating' and 'reviewCount' atomically!
      final result = await DatabaseMethods().addReview(
        productId: productId,
        userId: userId,
        rating: _rating.toInt(),
        reviewText: _reviewController.text.trim(),
      );

      _showSnackBar(result, isError: !result.contains("successfully"));

      if (mounted && result.contains("successfully")) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("An unexpected error occurred: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Write a Review', style: textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Review for ${widget.productData['Name'] ?? 'Product'}",
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              Text('Your Rating:', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 40,
                  glow: false, // Disables the glow effect for a cleaner look
                  ignoreGestures: _isLoading, 
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => Icon(
                    Icons.star,
                    color: colorScheme.primary,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() => _rating = rating);
                  },
                ),
              ),
              const SizedBox(height: 30),

              Text('Your Review:', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reviewController,
                maxLines: 5,
                enabled: !_isLoading,
                maxLength: 500, // Good practice to limit review length
                decoration: InputDecoration(
                  hintText: 'Share your thoughts about this product...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Review text cannot be empty.';
                  }
                  if (value.trim().length < 10) {
                    return 'Review must be at least 10 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(
                    _isLoading ? "Submitting..." : "Submit Review",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}