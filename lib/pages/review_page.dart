import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/utils/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AddReviewPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const AddReviewPage({super.key, required this.productData});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  /// Submits the review to the database.
  Future<void> _submitReview() async {
    // Basic validation
    if (_rating == 0) {
      _showSnackBar("Please provide a star rating.", isError: true);
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      _showSnackBar("Please write a review.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await SharedPreferenceHelper().getUserID();
      if (userId == null) {
        _showSnackBar("User not logged in.", isError: true);
        return;
      }

      final result = await DatabaseMethods().addReview(
        productId: widget.productData['id']!,
        userId: userId,
        rating: _rating.toInt(),
        reviewText: _reviewController.text.trim(),
      );

      _showSnackBar(result, isError: !result.contains("successfully"));

      if (mounted && result.contains("successfully")) {
        Navigator.pop(context); // Go back to the previous screen on success
      }
    } catch (e) {
      _showSnackBar("An unexpected error occurred.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: colorScheme.primary,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 24),

            // --- Text Review Section ---
            Text('Your Review:', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share your thoughts about this product...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
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
    );
  }
}
