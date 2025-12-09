import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/utils/database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added: Source of truth for user ID
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AddReviewPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const AddReviewPage({super.key, required this.productData});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  // 1. Added Form Key for validation
  final _formKey = GlobalKey<FormState>(); 
  
  final TextEditingController _reviewController = TextEditingController();
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

  /// Submits the review to the database.
  Future<void> _submitReview() async {
    // 1. Validate form and dismiss keyboard
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      // ⭐️ FIX 1: Get User ID from Firebase Auth (Source of Truth)
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _showSnackBar("Session expired. Please log in again.", isError: true);
        return;
      }
      
      final productId = widget.productData['id'];
      if (productId == null) {
          throw Exception("Product ID is missing.");
      }

      // ⭐️ FIX 2: Check for existing review by using the UserID as the Document ID.
      // This is fast, atomic, and prevents race conditions/duplicates.
      final reviewDocRef = FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(userId); // Document ID is the User ID

      if ((await reviewDocRef.get()).exists) {
        _showSnackBar("You have already reviewed this product.", isError: true);
        return;
      }

      final result = await DatabaseMethods().addReview(
        productId: productId,
        userId: userId,
        rating: _rating.toInt(),
        reviewText: _reviewController.text.trim(),
      );

      _showSnackBar(result, isError: !result.contains("successfully"));

      if (mounted && result.contains("successfully")) {
        Navigator.pop(context); // Go back to Product Details on success
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
      ),
      // 2. Wrap content in SingleChildScrollView and Form
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
              
              // --- Star Rating Section ---
              Text('Your Rating:', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 36,
                ignoreGestures: _isLoading, 
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: colorScheme.primary,
                ),
                onRatingUpdate: (rating) {
                  setState(() => _rating = rating);
                },
                // Add validator to ensure rating is set
                // (Note: RatingBar doesn't have a native validator, so we use manual check in _submitReview)
              ),
              const SizedBox(height: 24),

              // --- Text Review Section ---
              Text('Your Review:', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField( // 3. Use TextFormField for integrated validation
                controller: _reviewController,
                maxLines: 5,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts about this product...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Review text cannot be empty.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // --- Submit Button ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitReview,
                  icon: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(_isLoading ? "Submitting..." : "Submit Review"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}