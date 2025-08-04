import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/profile.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/utils/database.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String? userID;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    userID = await SharedPreferenceHelper().getUserID();
    if (mounted) setState(() {});
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

  /// Wrapper to prevent rapid-fire clicks on any cart action.
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

  /// Handles quantity updates with a Firestore Transaction.
  Future<void> updateItemQuantity(String itemId, int delta) async {
    if (userID == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(userID).collection('cart').doc(itemId);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          return;
        }

        final currentQuantity = (docSnapshot.data()?['quantity'] as int?) ?? 0;
        final newQuantity = currentQuantity + delta;

        if (newQuantity > 0) {
          transaction.update(docRef, {'quantity': newQuantity});
        } else {
          transaction.delete(docRef);
        }
      });

      if (mounted) {
        final itemInCart = cartProvider.cart.any((item) => item['id'] == itemId);
        if (!itemInCart) return;

        final currentLocalQuantity = cartProvider.cart.firstWhere((item) => item['id'] == itemId)['quantity'] as int;
        final newLocalQuantity = currentLocalQuantity + delta;
        
        if (newLocalQuantity > 0) {
          cartProvider.updateQuantity(itemId, delta);
        } else {
          cartProvider.removeFromCart(itemId);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Could not update item.', isError: true);
    }
  }

  /// Handles removing an item completely from the cart.
  Future<void> removeItem(String itemId) async {
    if (userID == null) return;
    
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final originalItem = Map<String, dynamic>.from(cartProvider.cart.firstWhere((i) => i['id'] == itemId));
    final originalIndex = cartProvider.cart.indexWhere((i) => i['id'] == itemId);

    cartProvider.removeFromCart(itemId);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userID).collection('cart').doc(itemId).delete();
    } catch (e) {
      if(mounted) {
        cartProvider.addItemAt(originalIndex, originalItem);
        _showSnackBar('Could not remove item. Please try again.', isError: true);
      }
    }
  }

  /// Handles placing the final order after validating the user's address.
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

    final prefs = SharedPreferenceHelper();
    final address = await prefs.getUserAddress();

    if (address == null ||
        address['state'] == null ||
        address['city'] == null ||
        address['local'] == null || (address['local'] as String).isEmpty ||
        address['pincode'] == null || (address['pincode'] as String).isEmpty ||
        address['mobile'] == null || (address['mobile'] as String).isEmpty) {
      _showSnackBar("Please complete your profile address first.", isError: true);
      // ignore: use_build_context_synchronously
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfilePage()));
      return;
    }

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

    final total = cart.fold<double>(0, (sum, item) {
      final price = item['Price'] as num? ?? 0;
      final quantity = item['quantity'] as num? ?? 0;
      return sum + (price * quantity);
    });

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  'Cart',
                  style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
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
            : Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 230),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
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
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['Name'] ?? 'No Name',
                                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '₹${item['Price']}',
                                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildQuantityButton(
                                          icon: Icons.remove,
                                          onPressed: () => _handleCartInteraction(() => updateItemQuantity(item['id'], -1)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('${item['quantity']}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                        ),
                                        _buildQuantityButton(
                                          icon: Icons.add,
                                          onPressed: () => _handleCartInteraction(() => updateItemQuantity(item['id'], 1)),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                          onPressed: () => _handleCartInteraction(() => removeItem(item['id'])),
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
                  Positioned(
                    bottom: 90,
                    left: 0,
                    right: 0,
                    child: _buildCheckoutSection(total),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildCheckoutSection(double total) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -10))],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: textTheme.titleLarge?.copyWith(color: Colors.grey[700])),
              Text('₹${total.toStringAsFixed(2)}', style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isBusy ? null : () => _handleCartInteraction(_handlePlaceOrder),
              child: _isBusy
                  ? CircularProgressIndicator(color: colorScheme.onPrimary)
                  : const Text("Place Order"),
            ),
          ),
        ],
      ),
    );
  }
}
