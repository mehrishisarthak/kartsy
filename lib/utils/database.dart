import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- CONSUMER: GET DATA ---
  
  /// Fetches product listings filtered by category
  Future<Stream<QuerySnapshot>> getListings(String category) async {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots();
  }

  /// Fetches order history for a specific user
  Future<List<Map<String, dynamic>>> fetchOrders(String userId) async {
    // Fetch from the user's private subcollection
    final ordersSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .get();
        
    return ordersSnapshot.docs.map((doc) => doc.data()).toList();
  }

  // --- CONSUMER: ACTIONS ---

  Future<void> addToCart(String userId, Map<String, dynamic> product) async {
    final cartRef = _firestore.collection('users').doc(userId).collection('cart').doc(product['id']);
    final doc = await cartRef.get();

    if (doc.exists) {
      await cartRef.update({'quantity': FieldValue.increment(1)});
    } else {
      await cartRef.set({
        'Name': product['Name'],
        'Price': product['Price'],
        'Image': product['Image'],
        'id': product['id'],
        'category': product['category'],
        'quantity': 1,
      });
    }
  }
  ///TODO : add logic for address parameter
  /// Handles the complex transaction of placing an order
  Future<String> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
    required CartProvider cartProvider,
    required String address,
  }) async {
    if (cartItems.isEmpty) return "Cannot place an order with an empty cart.";

    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    try {
      // 1. Generate a Single Order ID
      final orderDoc = _firestore.collection('orders').doc(); 
      final orderId = orderDoc.id;

      final double totalPrice = cartItems.fold(0.0, (sum, item) => sum + ((item['Price'] ?? 0) * (item['quantity'] ?? 0)));

      final orderData = {
        'orderId': orderId,
        'userId': userId,
        'items': cartItems,
        'totalPrice': totalPrice,
        'status': 'Pending',
        'timestamp': timestamp,
        'address': address, 
      };

      // 2. WRITE: User's History
      final userOrderRef = _firestore.collection('users').doc(userId).collection('orders').doc(orderId);
      batch.set(userOrderRef, orderData);

      // 3. WRITE: Global Orderbook
      batch.set(orderDoc, orderData);

      // 4. UPDATE: Inventory (Global + Admin Side)
      for (final item in cartItems) {
        final productId = item['id'];
        final quantity = item['quantity'];
        final adminId = item['adminId']; // <--- CRITICAL: Get Seller ID from item

        // A. Global Product Registry Reference
        final globalProductRef = _firestore.collection('products').doc(productId);
        
        // B. Admin/Seller Local Listing Reference
        final adminListingRef = _firestore
            .collection('Admin')
            .doc(adminId)
            .collection('listings')
            .doc(productId);

        // Queue Global Decrement
        batch.update(globalProductRef, {
          'inventory': FieldValue.increment(-quantity)
        });

        // Queue Seller Side Decrement (This was missing)
        batch.update(adminListingRef, {
          'inventory': FieldValue.increment(-quantity)
        });
      }

      // 5. DELETE: Clear User's Cart
      final cartQuerySnapshot = await _firestore.collection('users').doc(userId).collection('cart').get();
      for (final doc in cartQuerySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // 6. COMMIT ATOMICALLY
      // If any part of this fails (e.g., admin doc doesn't exist), the whole order is cancelled.
      await batch.commit();
      
      cartProvider.clearCart();
      return "Order placed successfully!";

    } catch (e) {
      print("⛔ Error placing order: $e");
      return "Failed to place order. Please try again later.";
    }
  }

  Future<String> addReview({
    required String productId,
    required String userId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      DocumentReference productRef = _firestore.collection('products').doc(productId);
      DocumentSnapshot productSnap = await productRef.get();
      
      if (!productSnap.exists) return "Product not found";

      Map<String, dynamic> productData = productSnap.data() as Map<String, dynamic>;
      
      double currentAvg = (productData['averageRating'] as num?)?.toDouble() ?? 0.0;
      int currentCount = (productData['reviewCount'] as num?)?.toInt() ?? 0;

      // Calculate New Average
      double newAvg = ((currentAvg * currentCount) + rating) / (currentCount + 1);

      WriteBatch batch = _firestore.batch();

      // Add to Subcollection
      DocumentReference reviewRef = productRef.collection('reviews').doc();
      batch.set(reviewRef, {
        'userId': userId,
        'rating': rating,
        'reviewText': reviewText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update Aggregates
      batch.update(productRef, {
        'averageRating': newAvg,
        'reviewCount': FieldValue.increment(1),
      });

      await batch.commit();
      return "Review submitted successfully!";
    } catch (e) {
      print("⛔ Error adding review: $e");
      return "Failed to submit review.";
    }
  }
}