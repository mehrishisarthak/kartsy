import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:ecommerce_shop/pages/review_page.dart';
import 'package:ecommerce_shop/utils/show_snackbar.dart';
import 'package:ecommerce_shop/widget/generic_list_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class InterestListPage extends StatefulWidget {
  final String userId;
  const InterestListPage({super.key, required this.userId});

  @override
  State<InterestListPage> createState() => _InterestListPageState();
}

class _InterestListPageState extends State<InterestListPage> {
  Future<void> _removeInterest(String docId) async {
    try {
      final leadRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('leads')
          .doc(docId);

      // 1. Fetch the document to get the adminId
      final leadSnap = await leadRef.get();
      final leadData = leadSnap.data();

      if (!leadSnap.exists || leadData == null) {
        // If the user's copy is already gone, just show success
        return;
      }

      final String adminId = leadData['adminId'] ?? 'super_admin'; // Fallback

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      // 2. Delete User's Copy (The original functionality)
      batch.delete(leadRef);

      // 3. ✅ FIX: Delete Seller's Copy
      final sellerRef = FirebaseFirestore.instance
          .collection('Admin')
          .doc(adminId)
          .collection('leads')
          .doc(docId); // Uses the same docId/leadId

      batch.delete(sellerRef);

      // 4. Commit the Atomic Deletion
      await batch.commit();

      if (mounted) {
        showCustomSnackBar(context, "Removed from interests",
            type: SnackBarType.success);
      }
    } catch (e) {
      debugPrint("Error removing interest: $e");
      if (mounted) {
        showCustomSnackBar(context, "Failed to remove: $e",
            type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // ✅ FIX 1: Use Theme Background
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Interests',
          style: textTheme.headlineSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor, // ✅ Match Scaffold
        automaticallyImplyLeading: false, // ✅ Removed Back Button
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('leads')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const GenericListShimmer();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'images/fallback.json',
                    height: 250,
                    repeat: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No interests yet!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      // ✅ FIX 2: Dynamic Text Color
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Items you inquire about will appear here.',
                    style: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final leads = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leads.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final leadDoc = leads[index];
              final leadData = leadDoc.data() as Map<String, dynamic>;
              final String productId = leadData['productId'] ?? '';

              return _buildInterestCard(
                context,
                leadData,
                docId: leadDoc.id,
                productId: productId,
                theme: theme, // Pass theme
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInterestCard(BuildContext context, Map<String, dynamic> data,
      {required String docId,
      required String productId,
      required ThemeData theme}) {
    String status = data['status'] ?? 'New';
    bool isWon = status == 'Won';

    Color statusColor;
    switch (status) {
      case 'Won':
        statusColor = Colors.green;
        break;
      case 'Lost':
        statusColor = Colors.red;
        break;
      case 'Contacted':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }

    return GestureDetector(
      onTap: productId.isNotEmpty
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProductDetails(productId: productId)))
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          // ✅ FIX 3: Use Card Color (Dark/Light aware)
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: data['productImage'] ?? '',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: theme.colorScheme.surfaceContainer),
                      errorWidget: (_, __, ___) =>
                          Icon(Icons.broken_image, color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['productName'] ?? 'Unknown Item',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${data['productPrice'] ?? '--'}',
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ FIX 4: Conditional Delete Button
                  if (!isWon)
                    IconButton(
                      tooltip: 'Remove from interests',
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => _showRemoveDialog(docId),
                    )
                  else
                    // Show a static checkmark or success indicator
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.verified, color: Colors.green.shade600),
                    ),
                ],
              ),
              if (isWon) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // ✅ FIX 3: Use the smart button to prevent duplicate reviews
                _ReviewStatusButton(
                  productId: productId,
                  userId: widget.userId,
                  data: data,
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Item?"),
        content: const Text("Remove this from your interests list?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeInterest(docId);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- Helper Widget to check review status (Issue #3) ---
class _ReviewStatusButton extends StatelessWidget {
  final String productId;
  final String userId;
  final Map<String, dynamic> data;
  final ThemeData theme;

  const _ReviewStatusButton({
    required this.productId,
    required this.userId,
    required this.data,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // We check for the review document named by the USER ID (as per fix for Issue #3 in database.dart)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        // If snapshot has data and the document exists, the user has already reviewed it
        if (snapshot.hasData && snapshot.data!.exists) {
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null, // Button disabled
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text("Reviewed",
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          );
        }

        // Otherwise, show the normal 'Write a Review' button
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddReviewPage(
                    productData: {
                      'id': productId,
                      'Name': data['productName'],
                      'Image': data['productImage'],
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.star_rate_rounded, size: 18),
            label: const Text("Write a Review"),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side:
                  BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );
      },
    );
  }
}
