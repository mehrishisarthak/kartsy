import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateProductInventory(String productId, int change) async {
    final productRef = _firestore.collection('products').doc(productId);
    final docSnapshot = await productRef.get();

    if (docSnapshot.exists) {
      await productRef.update({
        'inventory': FieldValue.increment(change),
      });
    }
  }

  // --- UPDATED ADD PRODUCT METHOD ---
  Future<void> addProduct(Map<String, dynamic> productData, String categoryName, String adminId) async {
    final String productId = productData['id'];

    // Prepare the master data map
    final productDataComplete = {
      ...productData,
      'adminId': adminId,
      'category': categoryName, // Ensure category is saved in the document
    };

    // 1. Write to global 'products' collection (Single Source of Truth)
    await _firestore.collection('products').doc(productId).set(productDataComplete);

    // 2. Write to Admin's personal listing (For their dashboard)
    await _firestore
        .collection('Admin')
        .doc(adminId)
        .collection('listings')
        .doc(productId)
        .set(productDataComplete);
        
    // REMOVED: await _firestore.collection(categoryName)...
  }

  // --- UPDATED GET LISTINGS METHOD ---
  Future<Stream<QuerySnapshot>> getListings(String category) async {
    // OLD WAY: return _firestore.collection(category).snapshots();
    
    // NEW WAY: Query the main collection and filter
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots();
  }
  
  Future<void> addToCart(String userId, Map<String, dynamic> product) async {
    final cartRef = _firestore.collection('users').doc(userId).collection('cart').doc(product['id']);

    final doc = await cartRef.get();

    if (doc.exists) {
      await cartRef.update({
        'quantity': FieldValue.increment(1),
      });
    } else {
      await cartRef.set({
        'Name': product['Name'],
        'Price': product['Price'],
        'Image': product['Image'],
        'id': product['id'],
        'adminId': product['adminId'] ?? product['adminID'],
        'category': product['category'],
        'quantity': 1,
      });
    }
  }

  Future<String> fetchAdminId(String username, String password) async {
    final querySnapshot = await _firestore
        .collection('Admin')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .where('password', isEqualTo: password.trim())
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return "";
  }

  Future<String> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
    required CartProvider cartProvider,
  }) async {
    if (cartItems.isEmpty) {
      return "Cannot place an order with an empty cart.";
    }

    final batch = _firestore.batch();

    try {
      final userOrderRef = _firestore.collection('users').doc(userId).collection('orders').doc();
      final consolidatedOrderId = userOrderRef.id;
      //iterate through all items in cart and add operation in batch for each item
      for (final productData in cartItems) {
        final adminId = productData['adminId'];
        final productId = productData['id'];
        final quantity = productData['quantity'];
        
        if (adminId == null || adminId.isEmpty) {
          continue;
        }
        //add confirmed order for admin pannel in batch for each item
        final adminOrderRef = _firestore.collection('Admin').doc(adminId).collection('orders').doc();
        batch.set(adminOrderRef, {
          'productName': productData['Name'],
          'productPrice': productData['Price'],
          'productImage': productData['Image'],
          'productId': productId,
          'quantity': quantity,
          'buyerId': userId,
          'orderStatus': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
          'consolidatedOrderId': consolidatedOrderId,
        });
        // reduce the item inventory from admin
        final productRef = _firestore.collection('products').doc(productId);
        batch.update(productRef, {'inventory': FieldValue.increment(-quantity)});
      }

      final double totalPrice = cartItems.fold(0.0, (sum, item) => sum + ((item['Price'] ?? 0) * (item['quantity'] ?? 0)));
      batch.set(userOrderRef, {
        'orderId': consolidatedOrderId,
        'items': cartItems,
        'totalPrice': totalPrice,
        'orderStatus': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      //delete items from cart of user (add in batch operation)
      final cartQuerySnapshot = await _firestore.collection('users').doc(userId).collection('cart').get();
      for (final doc in cartQuerySnapshot.docs) {
        batch.delete(doc.reference);
      }
      //all operations take place at once or not at all once we commit the batch, avoiding race conditions
      await batch.commit();
      //we clear the cart provider
      cartProvider.clearCart();

      return "Order placed successfully!";

    } catch (e) {
      print("⛔ Error placing order: $e");
      return "Failed to place order. Please try again later.";
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrders(String userId) async {
    final ordersSnapshot = await _firestore.collection('users').doc(userId).collection('orders').get();
    return ordersSnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<String> addReview({
    required String productId,
    required String userId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      // 1. Get Current Product Data (To calculate average)
      DocumentReference productRef = _firestore.collection('products').doc(productId);
      DocumentSnapshot productSnap = await productRef.get();
      
      if (!productSnap.exists) return "Product not found";

      Map<String, dynamic> productData = productSnap.data() as Map<String, dynamic>;
      
      // Get existing stats (Default to 0 if new)
      double currentAvg = (productData['averageRating'] as num?)?.toDouble() ?? 0.0;
      int currentCount = (productData['reviewCount'] as num?)?.toInt() ?? 0;

      // 2. Calculate New Average
      // Formula: ((OldAvg * OldCount) + NewRating) / (OldCount + 1)
      double newAvg = ((currentAvg * currentCount) + rating) / (currentCount + 1);

      // 3. Prepare Review Data
      final reviewData = {
        'userId': userId,
        'rating': rating,
        'reviewText': reviewText,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // 4. Batch Write (Atomic Safety)
      WriteBatch batch = _firestore.batch();

      // Add the review to subcollection
      DocumentReference reviewRef = productRef.collection('reviews').doc();
      batch.set(reviewRef, reviewData);

      // Update the Main Product Document with new stats
      batch.update(productRef, {
        'averageRating': newAvg,
        'reviewCount': FieldValue.increment(1),
      });

      await batch.commit();

      return "Review submitted successfully!";
    } catch (e) {
      print("⛔ Error adding review: $e");
      return "Failed to submit review. Please try again later.";
    }
  }
}