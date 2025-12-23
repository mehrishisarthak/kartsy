import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/review_page.dart';
import 'package:ecommerce_shop/services/shimmer/order_shimmer.dart';
import 'package:ecommerce_shop/utils/show_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class UserOrdersPage extends StatelessWidget {
  final String userId;
  const UserOrdersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Orders',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back, color: colorScheme.primary),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Active"),
              Tab(text: "Completed"),
            ],
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

            // Global Empty State (User has NEVER ordered anything)
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('images/emptyOrders.json',
                        height: 250, repeat: false),
                    const SizedBox(height: 20),
                    Text(
                      'No orders found yet!',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            final allOrders = snapshot.data!.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

            final activeOrders = allOrders
                .where((order) =>
                    order['orderStatus'] != 'Delivered' &&
                    order['orderStatus'] != 'Cancelled')
                .toList();

            final completedOrders = allOrders
                .where((order) =>
                    order['orderStatus'] == 'Delivered' ||
                    order['orderStatus'] == 'Cancelled')
                .toList();

            return TabBarView(
              children: [
                _buildOrderList(activeOrders, showReview: false),
                _buildOrderList(completedOrders, showReview: true),
              ],
            );
          },
        ),
      ),
    );
  }

  // ✅ FIXED: Centered Lottie for Empty Tabs
  Widget _buildOrderList(List<Map<String, dynamic>> orders,
      {required bool showReview}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Vertically Center
          crossAxisAlignment:
              CrossAxisAlignment.center, // Horizontally Center
          children: [
            Opacity(
              opacity: 0.8,
              child: Lottie.asset('images/emptyOrders.json',
                  height: 200, repeat: false),
            ),
            const SizedBox(height: 10),
            Text(
              "No orders in this category.",
              style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return OrderCard(
            order: orders[index], userId: userId, showReview: showReview);
      },
    );
  }
}

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

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showCustomSnackBar(context, "Order ID copied to clipboard!",
        type: SnackBarType.info);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final timestamp = (order['timestamp'] as Timestamp?)?.toDate();
    final items = (order['items'] as List).cast<Map<String, dynamic>>();

    String status = order['orderStatus'] ?? 'Pending';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Shipped':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping_outlined;
        break;
      case 'Delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timestamp != null
                          ? DateFormat('MMM dd, yyyy').format(timestamp)
                          : 'Unknown Date',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      timestamp != null
                          ? DateFormat('hh:mm a').format(timestamp)
                          : '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(status,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // --- ITEMS ---
            ...items.map((item) => OrderItemRow(
                item: item,
                userId: userId,
                showReviewButton: showReview && status == 'Delivered')),

            const Divider(height: 24),

            // --- FOOTER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _copyToClipboard(context, order['orderId']),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.copy, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "Copy Order ID",
                          style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                              decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'Total: ₹${(order['totalPrice'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item['Image'] ?? '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[100]),
              errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[100],
                  child: const Icon(Icons.broken_image)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['Name'] ?? 'Product',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Qty: ${item['quantity'] ?? 1}  •  ₹${item['Price']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                if (showReviewButton) ...[
                  const SizedBox(height: 8),
                  _ReviewActionButton(
                      productId: item['id'], userId: userId, itemData: item),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewActionButton extends StatelessWidget {
  final String productId;
  final String userId;
  final Map<String, dynamic> itemData;

  const _ReviewActionButton(
      {required this.productId, required this.userId, required this.itemData});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return const Text('✨ Reviewed',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold));
        }
        return SizedBox(
          height: 30,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddReviewPage(productData: itemData))),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            child: const Text("Write Review", style: TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }
}
