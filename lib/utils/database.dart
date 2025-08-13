import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- New method to update a product's inventory count ---
  Future<void> updateProductInventory(String productId, int change) async {
    final productRef = _firestore.collection('products').doc(productId);
    final docSnapshot = await productRef.get();

    if (docSnapshot.exists) {
      await productRef.update({
        'inventory': FieldValue.increment(change),
      });
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData, String categoryName, String adminId) async {
    final String productId = productData['id'];

    final productDataWithAdmin = {
      ...productData,
      'adminId': adminId,
    };

    await _firestore.collection(categoryName).doc(productId).set(productDataWithAdmin);

    await _firestore.collection('products').doc(productId).set({
      ...productDataWithAdmin,
      'category': categoryName
    });

    await _firestore
        .collection('Admin')
        .doc(adminId)
        .collection('listings')
        .doc(productId)
        .set(productDataWithAdmin);
  }

  Future<Stream<QuerySnapshot>> getListings(String category) async {
    return _firestore.collection(category).snapshots();
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
      // --- 1. Create order entries for each respective admin and update inventory ---
      for (final productData in cartItems) {
        final adminId = productData['adminId'];
        final productId = productData['id'];
        final quantity = productData['quantity'];
        
        if (adminId == null || adminId.isEmpty) {
          continue;
        }

        // Add the order to the admin's collection
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
        });
        
        // Use FieldValue.increment() for a safe, atomic inventory update
        final productRef = _firestore.collection('products').doc(productId);
        batch.update(productRef, {'inventory': FieldValue.increment(-quantity)});
      }

      // --- 2. Create a single, consolidated order for the user ---
      final userOrderRef = _firestore.collection('users').doc(userId).collection('orders').doc();
      final double totalPrice = cartItems.fold(0.0, (sum, item) => sum + ((item['Price'] ?? 0) * (item['quantity'] ?? 0)));
      batch.set(userOrderRef, {
        'orderId': userOrderRef.id,
        'items': cartItems,
        'totalPrice': totalPrice,
        'orderStatus': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // --- 3. Delete all documents from the user's cart ---
      final cartQuerySnapshot = await _firestore.collection('users').doc(userId).collection('cart').get();
      for (final doc in cartQuerySnapshot.docs) {
        batch.delete(doc.reference);
      }

      // --- 4. Commit all batched operations at once ---
      await batch.commit();

      // --- 5. If successful, clear the local cart provider ---
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
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return "User not found.";
      }

      final userName = userDoc.data()?['Name'] ?? 'Anonymous User';
      final userImage = userDoc.data()?['Image'] ?? '';

      final reviewData = {
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
        'rating': rating,
        'reviewText': reviewText,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .add(reviewData);

      return "Review submitted successfully!";
    } catch (e) {
      print("⛔ Error adding review: $e");
      return "Failed to submit review. Please try again later.";
    }
  }
  
}