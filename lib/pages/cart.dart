import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
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
  // State variable to track if an operation is in progress.
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    userID = await SharedPreferenceHelper().getUserID();
    if (mounted) {
      setState(() {});
    }
  }

  /// Wraps any cart action to handle the busy state.
  /// It disables buttons, runs the action, waits 1 second, then re-enables them.
  Future<void> _handleCartInteraction(Future<void> Function() action) async {
    if (_isBusy) return; // Prevent new actions while one is in progress

    setState(() => _isBusy = true);

    try {
      await action();
    } finally {
      // Wait 1 second before allowing another interaction
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  /// Updates item quantity with optimistic UI and rollback.
  Future<void> updateItemQuantity(String id, int delta) async {
    if (userID == null) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    // Optimistic UI update
    cartProvider.updateQuantity(id, delta);

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(userID).collection('cart').doc(id);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final newQuantity = (snapshot.data()?['quantity'] ?? 0) + delta;

        if (newQuantity <= 0) {
          transaction.delete(docRef);
        } else {
          transaction.update(docRef, {'quantity': FieldValue.increment(delta)});
        }
      });
    } catch (e) {
      // Rollback on failure
      cartProvider.updateQuantity(id, -delta);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update item. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Removes an item with optimistic UI and rollback.
  Future<void> removeItem(String id) async {
    if (userID == null) return;
    
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    // Find the item to be removed so we can add it back on failure
    final itemIndex = cartProvider.cart.indexWhere((item) => item['id'] == id);
    if (itemIndex == -1) return;
    final itemToRemove = cartProvider.cart[itemIndex];

    // Optimistic UI update
    cartProvider.removeFromCart(id);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userID).collection('cart').doc(id).delete();
    } catch (e) {
      // Rollback on failure
      cartProvider.addItemAt(itemIndex, itemToRemove);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not remove item. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cart = cartProvider.cart;

    final total = cart.fold<double>(
        0, (sum, item) => sum + (item['price'] as num) * (item['quantity'] as num));

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
                      final itemId = item['id'];

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
                                item['image'],
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
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: AppWidget.boldTextStyle().copyWith(
                                        fontSize: 20,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₹${item['price']} x ${item['quantity']}',
                                      style: GoogleFonts.lato(
                                        fontSize: 16,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          onPressed: _isBusy ? null : () => _handleCartInteraction(
                                            () => updateItemQuantity(itemId, -1),
                                          ),
                                        ),
                                        Text('${item['quantity']}', style: AppWidget.boldTextStyle()),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          onPressed: _isBusy ? null : () => _handleCartInteraction(
                                            () => updateItemQuantity(itemId, 1),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: _isBusy ? null : () => _handleCartInteraction(
                                            () => removeItem(itemId),
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
                            // Disable checkout button during cart interactions
                            onPressed: _isBusy ? null : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text("Order placed successfully!"),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              // ignore: deprecated_member_use
                              disabledBackgroundColor: Colors.blue.withOpacity(0.5),
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
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