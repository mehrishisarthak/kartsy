import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/utils/database.dart';
import 'package:ecommerce_shop/widget/support_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        backgroundColor: isError ? Colors.red : Colors.green,
      ));
  }

  /// Wrapper to prevent rapid-fire clicks on any cart action.
  Future<void> _handleCartInteraction(Future<void> Function() action) async {
    if (_isBusy) return;
    if (mounted) setState(() => _isBusy = true);

    try {
      await action();
    } finally {
      // Small delay to let UI updates settle
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// ✅ FIX: Handles quantity updates with a Firestore Transaction.
  /// This is the safest way to prevent race conditions. It reads the
  /// current quantity from the database *then* writes the new value
  /// in one single, unbreakable operation.
  Future<void> updateItemQuantity(String itemId, int delta) async {
    if (userID == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(userID).collection('cart').doc(itemId);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          print("Item document does not exist, cannot update.");
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

      // Update local state AFTER the transaction is confirmed successful
      if (mounted) {
        final itemInCart = cartProvider.cart.any((item) => item['id'] == itemId);
        if(!itemInCart) return;

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
      print("Error during transaction: $e");
    }
  }

  /// Handles removing an item completely from the cart.
  Future<void> removeItem(String itemId) async {
    if (userID == null) return;
    
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final originalItem = Map<String, dynamic>.from(cartProvider.cart.firstWhere((i) => i['id'] == itemId));
    final originalIndex = cartProvider.cart.indexWhere((i) => i['id'] == itemId);

    // Optimistic UI update
    cartProvider.removeFromCart(itemId);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userID).collection('cart').doc(itemId).delete();
    } catch (e) {
      // Revert UI on error
      if(mounted) {
        cartProvider.addItemAt(originalIndex, originalItem);
        _showSnackBar('Could not remove item. Please try again.', isError: true);
      }
    }
  }

  /// Handles placing the final order.
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

    final total = cart.fold<double>(0, (sum, item) {
      final price = item['Price'] as num? ?? 0;
      final quantity = item['quantity'] as num? ?? 0;
      return sum + (price * quantity);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  'Cart',
                  style: AppWidget.boldTextStyle().copyWith(
                        fontSize: 30,
                        color: Colors.blue,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('images/emptyCart.json', height: 300),
                  const SizedBox(height: 20),
                  Text(
                    'Your cart is empty!',
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 140),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['Name'] ?? 'No Name',
                                      style: AppWidget.boldTextStyle().copyWith(fontSize: 20, color: Colors.black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₹${item['Price']} x ${item['quantity']}',
                                      style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[800]),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          onPressed: _isBusy ? null : () => _handleCartInteraction(
                                            () => updateItemQuantity(item['id'], -1),
                                          ),
                                        ),
                                        Text('${item['quantity']}', style: AppWidget.boldTextStyle()),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          onPressed: _isBusy ? null : () => _handleCartInteraction(
                                            () => updateItemQuantity(item['id'], 1),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: _isBusy ? null : () => _handleCartInteraction(
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
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3))],
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total', style: AppWidget.boldTextStyle().copyWith(fontSize: 18)),
                                Text('₹${total.toStringAsFixed(2)}', style: AppWidget.boldTextStyle().copyWith(fontSize: 20, color: Colors.blue)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isBusy ? null : () => _handleCartInteraction(_handlePlaceOrder),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              disabledBackgroundColor: Colors.blue.withOpacity(0.5),
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isBusy
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "Place Order",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}