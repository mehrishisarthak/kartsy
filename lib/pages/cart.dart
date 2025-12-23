import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/order_screen.dart';
import 'package:ecommerce_shop/pages/profile.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/firestore_service.dart';
import 'package:ecommerce_shop/utils/show_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  final String userId;
  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isPlacingOrder = false;

  // --- ORDER PLACEMENT LOGIC ---
  Future<void> _handlePlaceOrder() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (cartProvider.cart.isEmpty) {
      showCustomSnackBar(context, "Your cart is empty.",
          type: SnackBarType.error);
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      // 1. Get latest user data from FirestoreService
      final userData = await FirestoreService().getUser(widget.userId);
      final addressMap = userData?['Address'] as Map<String, dynamic>?;

      // 2. Validate Address
      if (addressMap == null ||
          (addressMap['state'] as String?)?.isEmpty == true ||
          (addressMap['local'] as String?)?.isEmpty == true ||
          (addressMap['pincode'] as String?)?.isEmpty == true ||
          (addressMap['mobile'] as String?)?.isEmpty == true) {
        showCustomSnackBar(
            context, "Please complete your profile address first.",
            type: SnackBarType.error);

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfilePage(userId: widget.userId),
            ),
          );
        }
        return;
      }

      // 3. Format Address
      String formattedAddress =
          "${addressMap['local']}, ${addressMap['city'] ?? ''}, ${addressMap['state']} - ${addressMap['pincode']}\nPhone: ${addressMap['mobile']}";

      // 4. Place Order via CartProvider
      final result = await cartProvider.placeOrder(
        userId: widget.userId,
        address: formattedAddress,
      );

      if (mounted) {
        showCustomSnackBar(context, result,
            type: result.contains("successfully")
                ? SnackBarType.success
                : SnackBarType.error);

        if (result.contains("successfully")) {
          // Navigate to Orders Page on success
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => UserOrdersPage(userId: widget.userId)),
          );
        }
      }
    } catch (e) {
      showCustomSnackBar(context, "Error placing order: $e",
          type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }


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
              BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Cart',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      tooltip: 'My Orders',
                      icon:
                          Icon(Icons.receipt_long, color: colorScheme.primary),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  UserOrdersPage(userId: widget.userId)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ✅ 1. STREAM BUILDER (The Source of Truth)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getCartStream(widget.userId),
        builder: (context, snapshot) {
          // ✅ 2. PASS DATA TO PROVIDER (Smart Merge)
          if (snapshot.hasData) {
            final List<Map<String, dynamic>> streamData = snapshot.data!.docs
                .map((doc) =>
                    {'id': doc.id, ...doc.data() as Map<String, dynamic>})
                .toList();

            // Use Microtask to update provider safely
            Future.microtask(() =>
                Provider.of<CartProvider>(context, listen: false)
                    .updateCartFromStream(streamData));
          }

          // ✅ 3. BUILD UI FROM PROVIDER
          return Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              final cart = cartProvider.cart;

              if (cart.isEmpty) {
                // Show Empty State only if stream is loaded and empty
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset('images/emptyCart.json', height: 300),
                      const SizedBox(height: 20),
                      Text(
                        'Your cart is empty!',
                        style: textTheme.headlineSmall?.copyWith(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }

              // Calculate Total
              final total = cartProvider.getTotalPrice();

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return _buildCartItem(context, item, cartProvider);
                      },
                    ),
                  ),
                  _buildCheckoutSection(total, cartProvider),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCartItem(
      BuildContext context, Map<String, dynamic> item, CartProvider provider) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final int inventory =
        int.tryParse(item['inventory']?.toString() ?? '0') ?? 0;
    final int quantity = item['quantity'] ?? 1;
    final String productId = item['id'];
    final bool isLoading = provider.isItemLoading(productId);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: item['Image'] ?? '',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 80, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['Name'] ?? 'No Name',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('₹${item['Price']}',
                      style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary)),
                  if (inventory < 10)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                          inventory > 0
                              ? 'Only $inventory left!'
                              : 'Out of Stock',
                          style: textTheme.bodySmall?.copyWith(
                              color: inventory > 0
                                  ? Colors.orange
                                  : colorScheme.error,
                              fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 8),

                  // CONTROLS ROW
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        isEnabled: quantity > 1,
                        onPressed: () {
                          // ✅ Call Provider (Debounced)
                          provider.updateQuantity(
                              widget.userId, productId, quantity - 1, inventory);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : Text('$quantity',
                                style: textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        isEnabled: quantity < inventory,
                        onPressed: () {
                          // ✅ Call Provider (Debounced)
                          provider.updateQuantity(
                              widget.userId, productId, quantity + 1, inventory);
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove from cart',
                        icon:
                            Icon(Icons.delete_outline, color: colorScheme.error),
                        onPressed: () {
                          // ✅ Call Provider
                          provider.removeFromCart(widget.userId, productId);
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed, bool isEnabled = true}) {
    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(double total, CartProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 20, offset: const Offset(0, -10))],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[700])),
              Text('₹${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
              child: _isPlacingOrder
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Place Order"),
            ),
          ),
        ],
      ),
    );
  }
}