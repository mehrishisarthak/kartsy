import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CartProvider with ChangeNotifier {
  // Local cache of cart items
  List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> get cart => _cart;

  // Track loading state per item (for spinner on specific card)
  final Map<String, bool> _loadingItems = {};
  bool isItemLoading(String productId) => _loadingItems[productId] ?? false;

  // ✅ CRITICAL: Map to store active timers for each product
  final Map<String, Timer> _debounceTimers = {};

  // ===========================================================================
  // 1. SMART STREAM MERGE (Prevents "Jumping" Glitch)
  // ===========================================================================
  void updateCartFromStream(List<Map<String, dynamic>> streamCart) {
    List<Map<String, dynamic>> mergedCart = [];

    for (var streamItem in streamCart) {
      final productId = streamItem['id'];

      // Check: Is the user currently modifying this item? (Is a timer active?)
      if (_debounceTimers.containsKey(productId)) {
        // YES: The user is clicking. Ignore the server update for this item.
        // Keep our local optimistic version.
        final localItem = _cart.firstWhere(
          (item) => item['id'] == productId, 
          orElse: () => streamItem
        );
        mergedCart.add(localItem);
      } else {
        // NO: The user is idle. Trust the server data.
        mergedCart.add(streamItem);
      }
    }

    _cart = mergedCart;
    notifyListeners();
  }

  // ===========================================================================
  // 2. DEBOUNCED QUANTITY UPDATE (1500ms Wait)
  // ===========================================================================
  Future<void> updateQuantity(String userId, String productId, int newQuantity, int stock) async {
    // A. Optimistic Update (Instant UI Change)
    final index = _cart.indexWhere((item) => item['id'] == productId);
    if (index != -1) {
      if (newQuantity > stock) return; // Prevent exceeding stock
      // Note: We handle removal (quantity 0) in the UI or a separate remove function
      
      _cart[index]['quantity'] = newQuantity;
      notifyListeners(); // Update UI immediately
    }

    // B. Cancel any existing timer for this product (Reset the clock)
    if (_debounceTimers[productId]?.isActive ?? false) {
      _debounceTimers[productId]!.cancel();
    }

    // C. Start a new timer (Wait 1.5 seconds)
    // The presence of this timer tells `updateCartFromStream` to BACK OFF.
    _debounceTimers[productId] = Timer(const Duration(milliseconds: 1500), () async {
      
      // D. Set Loading Indicator (Optional visual feedback)
      _loadingItems[productId] = true;
      notifyListeners();

      try {
        // E. THE ACTUAL WRITE (Happens only once per sequence)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(productId)
            .update({'quantity': newQuantity});
            
      } catch (e) {
        debugPrint("Cart Sync Error: $e");
        // Optional: Revert local state or show snackbar if server fails
      } finally {
        // F. CLEANUP
        // Removing the timer allows the Stream to take over again as the "Source of Truth"
        _loadingItems[productId] = false;
        _debounceTimers.remove(productId); 
        notifyListeners();
      }
    });
  }

  // ===========================================================================
  // 3. STANDARD ADD TO CART (Initial Add)
  // ===========================================================================
  Future<void> addToCart(String userId, Map<String, dynamic> product) async {
    final existingIndex = _cart.indexWhere((item) => item['id'] == product['id']);

    if (existingIndex != -1) {
      // Item exists? Use the smart update logic
      final currentQty = _cart[existingIndex]['quantity'] as int? ?? 1;
      final stock = int.tryParse(product['inventory'].toString()) ?? 100;
      await updateQuantity(userId, product['id'], currentQty + 1, stock);
    } else {
      // Item is new? Add directly (no debounce needed for first add)
      final newItem = {
        ...product, 
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
      };
      
      // Optimistic Add
      _cart.add(newItem);
      notifyListeners();

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(product['id'])
            .set(newItem);
      } catch (e) {
        debugPrint("Add to Cart Error: $e");
        _cart.removeWhere((item) => item['id'] == product['id']); // Revert on fail
        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // 4. HELPERS
  // ===========================================================================

  void removeFromCart(String userId, String productId) {
    // Optimistic Remove
    _cart.removeWhere((item) => item['id'] == productId);
    notifyListeners();

    // Fire & Forget Delete
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  double getTotalPrice() {
    return _cart.fold<double>(0, (sum, item) {
      final price = (item['Price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (item['quantity'] as int?) ?? 0;
      return sum + (price * quantity);
    });
  }
  
  void setCart(List<Map<String, dynamic>> items) {
    // Only used for initial load or manual overrides
    if (_debounceTimers.isEmpty) {
      _cart = items;
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    // Cancel all timers to prevent late writes
    _debounceTimers.forEach((key, timer) => timer.cancel());
    _debounceTimers.clear();
    notifyListeners();
  }
}