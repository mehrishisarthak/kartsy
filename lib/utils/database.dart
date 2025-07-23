import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';

//TODO : the return type of all functions should be Future<String> so we can handle errors properly
//TODO : needs rework like hashing the password for admin login/creation
//TODO : fix other files according to change no.1
class DatabaseMethods {
  Future<void> addProduct(Map<String, dynamic> productData, String categoryName, String adminId) async {
    final firestore = FirebaseFirestore.instance;
    final String productId = productData['id'];

    // Add the adminId to the product data itself for future reference
    final productDataWithAdmin = {
      ...productData,
      'adminId': adminId,
    };

    // Add to category-specific collection using product ID
    await firestore.collection(categoryName).doc(productId).set(productDataWithAdmin);

    // Add to global 'products' collection using same product ID
    await firestore.collection('products').doc(productId).set({
      ...productDataWithAdmin,
      'category': categoryName
    });

    // Add to admin's personal listing using same product ID
    await firestore
        .collection('Admin')
        .doc(adminId)
        .collection('listings')
        .doc(productId)
        .set(productDataWithAdmin); 
  }

  Future<Stream<QuerySnapshot>> getListings(String category) async {
    return FirebaseFirestore.instance.collection(category).snapshots();
  }

  Future<void> addToCart(String userId, Map<String, dynamic> product) async {
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(product['id']);

    final doc = await cartRef.get();

    if (doc.exists) {
      // Already in cart → update quantity
      await cartRef.update({
        'quantity': FieldValue.increment(1),
      });
    } else {
      // Not in cart → add new
      await cartRef.set({
        'Name': product['Name'],
        'Price': product['Price'],
        'Image': product['Image'],
        'id': product['id'],
        // ✅ FIX: This makes the code robust. It checks for the new 'adminId' key first,
        // and if it's not there, it falls back to checking for the old 'adminID' key.
        'adminId': product['adminId'] ?? product['adminID'],
        'category': product['category'],
        'quantity': 1,
      });
    }
  }

  Future<String> fetchAdminId(String username, String password) async {
    final querySnapshot = await FirebaseFirestore.instance
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

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      // --- 1. Create order entries for each respective admin ---
      for (final productData in cartItems) {
        
        // ⭐️ SUPER DEBUG: This will print the entire content of the cart item.
        print("--- DEBUG: Processing Cart Item ---");
        print(productData);
        print("------------------------------------");

        final adminId = productData['adminId'];
        if (adminId == null || adminId.isEmpty) {
          print("Skipping item with missing adminId: ${productData['Name']}");
          continue;
        }

        final adminOrderRef = firestore
            .collection('Admin')
            .doc(adminId)
            .collection('orders')
            .doc();

        batch.set(adminOrderRef, {
          'productName': productData['Name'],
          'productPrice': productData['Price'],
          'productImage': productData['Image'],
          'productId': productData['id'],
          'quantity': productData['quantity'],
          'buyerId': userId,
          'orderStatus': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // --- 2. Create a single, consolidated order for the user ---
      final userOrderRef = firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc();

      final double totalPrice = cartItems.fold(0.0, (sum, item) => sum + ((item['Price'] ?? 0) * (item['quantity'] ?? 0)));

      batch.set(userOrderRef, {
        'orderId': userOrderRef.id,
        'items': cartItems,
        'totalPrice': totalPrice,
        'orderStatus': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // --- 3. Get all documents from the user's cart to delete them ---
      final cartQuerySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

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
}
