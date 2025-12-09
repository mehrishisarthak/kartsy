import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/order_screen.dart';
import 'package:ecommerce_shop/pages/profile.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/utils/database.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  // BottomBar guarantees this is called only when logged in,
  // so userId is non-nullable.
  final String userId;

  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String? userID;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    // Using widget.userId directly (non-null)
    userID = widget.userId;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Theme.of(context).colorScheme.error : Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  Future<void> _handleCartInteraction(Future<void> Function() action) async {
    if (_isBusy) return;
    if (mounted) setState(() => _isBusy = true);

    try {
      await action();
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> updateItemQuantity(String itemId, int delta) async {
    if (userID == null) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final itemInCart = cartProvider.cart
        .firstWhere((item) => item['id'] == itemId, orElse: () => {});

    final int currentLocalQuantity = itemInCart['quantity'] as int? ?? 0;
    final int? productInventory = itemInCart['inventory'] as int?;

    // Local inventory limit check
    if (delta > 0 &&
        (productInventory != null &&
            currentLocalQuantity >= productInventory)) {
      _showSnackBar('Maximum stock reached for this item.', isError: true);
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .collection('cart')
        .doc(itemId);

    try {
      // Atomic quantity update in Firestore transaction. [web:22][web:27]
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) return;

        final currentQuantity =
            (docSnapshot.data()?['quantity'] as int?) ?? 0;
        final newQuantity = currentQuantity + delta;

        if (newQuantity > 0) {
          transaction.update(docRef, {'quantity': newQuantity});
        } else {
          transaction.delete(docRef);
        }
      });

      if (mounted) {
        if (delta < 0 && currentLocalQuantity <= 1) {
          cartProvider.removeFromCart(itemId);
        } else {
          cartProvider.updateQuantity(itemId, delta);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Could not update item.', isError: true);
      }
    }
  }

  Future<void> removeItem(String itemId) async {
    if (userID == null) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final originalItem =
        Map<String, dynamic>.from(cartProvider.cart.firstWhere(
      (i) => i['id'] == itemId,
    ));
    final originalIndex =
        cartProvider.cart.indexWhere((i) => i['id'] == itemId);

    // Optimistic UI remove
    cartProvider.removeFromCart(itemId);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .collection('cart')
          .doc(itemId)
          .delete();
    } catch (e) {
      if (mounted) {
        // Rollback on failure
        cartProvider.addItemAt(originalIndex, originalItem);
        _showSnackBar('Could not remove item. Please try again.',
            isError: true);
      }
    }
  }

  // Address validation via Firestore user document. [web:24][web:31]
  Future<void> _handlePlaceOrder() async {
    if (userID == null) {
      _showSnackBar("Please log in to place an order.", isError: true);
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.cart.isEmpty) {
      _showSnackBar("Your cart is empty.", isError: true);
      return;
    }

    // 1. Get latest address from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .get();
    final address = userDoc.data()?['Address'] as Map<String, dynamic>?;

    // 2. Robust address validation
    if (address == null ||
        (address['state'] as String?)?.isEmpty == true ||
        (address['local'] as String?)?.isEmpty == true ||
        (address['pincode'] as String?)?.isEmpty == true ||
        (address['mobile'] as String?)?.isEmpty == true) {
      _showSnackBar("Please complete your profile address first.",
          isError: true);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProfilePage(userId: userID!),
          ),
        );
      }
      return;
    }

    // 3. Place order using verified data
    final result = await DatabaseMethods().placeOrder(
      userId: userID!,
      cartItems: List<Map<String, dynamic>>.from(cartProvider.cart),
      cartProvider: cartProvider,
    );

    _showSnackBar(result, isError: !result.contains("successfully"));
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cart = cartProvider.cart;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Local total calculation from cart list. [web:25][web:34]
    final total = cart.fold<double>(0, (summation, item) {
      final price = item['Price'] as num? ?? 0;
      final quantity = item['quantity'] as num? ?? 0;
      return summation + (price * quantity);
    });

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
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
                      icon: Icon(
                        Icons.shopping_bag_outlined,
                        color: colorScheme.primary,
                      ),
                      // userId is guaranteed non-null in this widget
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                UserOrdersPage(userId: widget.userId),
                          ),
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
      body: SafeArea(
        top: false,
        bottom: false,
        child: cart.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lottie empty cart animation. [web:32][web:29]
                    Lottie.asset('images/emptyCart.json', height: 300),
                    const SizedBox(height: 20),
                    Text(
                      'Your cart is empty!',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        final int inventory =
                            int.tryParse(item['inventory']?.toString() ?? '0') ??
                                0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                                child: Image.network(
                                  item['Image'] ?? '',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 80),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['Name'] ?? 'No Name',
                                        style: textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight:
                                                    FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '₹${item['Price']}',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      if (inventory < 10)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 4.0),
                                          child: Text(
                                            inventory > 0
                                                ? 'Only $inventory left!'
                                                : 'Out of Stock',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                              color: inventory > 0
                                                  ? Colors.orange
                                                  : colorScheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildQuantityButton(
                                            icon: Icons.remove,
                                            onPressed: () =>
                                                _handleCartInteraction(
                                              () => updateItemQuantity(
                                                  item['id'], -1),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8.0),
                                            child: Text(
                                              '${item['quantity']}',
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          _buildQuantityButton(
                                            icon: Icons.add,
                                            onPressed: () =>
                                                _handleCartInteraction(
                                              () => updateItemQuantity(
                                                  item['id'], 1),
                                            ),
                                            isEnabled: inventory > 0 &&
                                                (item['quantity'] as int) <
                                                    inventory,
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: colorScheme.error,
                                            ),
                                            onPressed: () =>
                                                _handleCartInteraction(
                                              () => removeItem(item['id']),
                                            ),
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
                      },
                    ),
                  ),
                  _buildCheckoutSection(total),
                ],
              ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(double total) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, -10),
          )
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: textTheme.titleLarge
                    ?.copyWith(color: Colors.grey[700]),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isBusy
                  ? null
                  : () => _handleCartInteraction(_handlePlaceOrder),
              child: _isBusy
                  ? CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                    )
                  : const Text("Place Order"),
            ),
          ),
        ],
      ),
    );
  }
}
