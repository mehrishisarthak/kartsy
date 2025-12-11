import 'package:cached_network_image/cached_network_image.dart'; // ✅ Added for performance
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/review_page.dart';
import 'package:ecommerce_shop/services/shimmer/order_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class UserOrdersPage extends StatelessWidget {
  final String userId;
  const UserOrdersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: colorScheme.primary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
                    child: Text(
                      'My Orders',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: OrdersShimmer());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading orders.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('images/emptyOrders.json', height: 300),
                  const SizedBox(height: 20),
                  Text(
                    'You haven\'t placed any orders yet.',
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final allOrders = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          
          final liveOrders = allOrders
              .where((order) => order['orderStatus'] != 'Delivered')
              .toList();
          final deliveredOrders = allOrders
              .where((order) => order['orderStatus'] == 'Delivered')
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (liveOrders.isNotEmpty) ...[
                  Text('Live Orders',
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...liveOrders.map((order) => OrderCard(
                      order: order, userId: userId, showReview: false)),
                  const SizedBox(height: 30),
                ],
                if (deliveredOrders.isNotEmpty) ...[
                  Text('Delivered Orders',
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...deliveredOrders.map((order) => OrderCard(
                      order: order, userId: userId, showReview: true)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ✅ Extracted Widget to prevent massive rebuilds
class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String userId;
  final bool showReview;

  const OrderCard({
    super.key,
    required this.order,
    required this.userId,
    required this.showReview,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final timestamp = (order['timestamp'] as Timestamp?)?.toDate();

    Color statusColor;
    switch (order['orderStatus']) {
      case 'Shipped':
        statusColor = Colors.blue;
        break;
      case 'Delivered':
        statusColor = Colors.green;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange; // Pending
    }

    final items = (order['items'] as List).cast<Map<String, dynamic>>();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ID: ${order['orderId']}',
                  style:
                      textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['orderStatus'] ?? 'Pending',
                    style: textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ordered on: ${timestamp != null ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp) : 'N/A'}',
              style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const Divider(height: 20),
            ...items.map((item) => OrderItemRow(
                  item: item,
                  userId: userId,
                  showReviewButton: showReview,
                )),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  '₹${(order['totalPrice'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Extracted Row for cleaner code and caching
class OrderItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final String userId;
  final bool showReviewButton;

  const OrderItemRow({
    super.key,
    required this.item,
    required this.userId,
    required this.showReviewButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ OPTIMIZED: Cached Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item['Image'] ?? '',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['Name'] ?? 'Unknown Product',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item['quantity'] ?? 1}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${(item['Price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                
                // Review Logic Isolated here
                if (showReviewButton) ...[
                  const SizedBox(height: 8),
                  _ReviewActionButton(productId: item['id'], userId: userId, itemData: item),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ ISOLATED WIDGET to handle the Stream
// This prevents the entire page from refreshing just to check reviews
class _ReviewActionButton extends StatelessWidget {
  final String productId;
  final String userId;
  final Map<String, dynamic> itemData;

  const _ReviewActionButton({
    required this.productId,
    required this.userId,
    required this.itemData,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .limit(1) // Limit 1 is crucial for cost optimization
          .snapshots(),
      builder: (context, snapshot) {
        // Loading state: small invisible box to prevent jumpiness
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 30, width: 80);
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return const Row(
            children: [
              Icon(Icons.verified_user, color: Colors.blue, size: 16),
              SizedBox(width: 4),
              Text('Reviewed', style: TextStyle(fontSize: 12, color: Colors.blue)),
            ],
          );
        }

        return ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddReviewPage(productData: itemData),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            minimumSize: const Size(80, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduces padding
          ),
          child: const Text('Review', style: TextStyle(fontSize: 12)),
        );
      },
    );
  }
}