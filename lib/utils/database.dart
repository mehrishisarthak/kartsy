import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // ===========================================================================
  // 🤝 LEAD GENERATION (User -> Seller Interest)
  // ===========================================================================

  /// Adds a lead to the specific Admin's sub-collection
  Future<void> addLeadToSeller({
    required String adminId,
    required Map<String, dynamic> leadData,
  }) async {
    try {
      // Reference to the specific Admin's leads collection
      final leadDocRef = _firestore
          .collection('Admin')
          .doc(adminId)
          .collection('leads')
          .doc(); // Generate ID automatically

      // Add the ID to the data payload
      final completeData = {
        ...leadData,
        'leadId': leadDocRef.id,
        'adminId': adminId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'New', // Default status
      };

      await leadDocRef.set(completeData);
    } catch (e) {
      print("Error adding lead: $e");
      rethrow;
    }
  }

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
  // ===========================================================================
  // 🛒 MARKETPLACE ORDER PLACEMENT (The "Fan-Out" Logic)
  // ===========================================================================

  Future<String> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
    required String address,
    required var cartProvider, // Pass provider to clear it later
  }) async {
    try {
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // 1. GROUP ITEMS BY SELLER (AdminID)
      // This ensures Seller A doesn't see Seller B's items.
      Map<String, List<Map<String, dynamic>>> orderGroups = {};

      for (var item in cartItems) {
        String sellerId = item['adminId'] ?? 'super_admin'; // Fallback for safety
        
        if (!orderGroups.containsKey(sellerId)) {
          orderGroups[sellerId] = [];
        }
        orderGroups[sellerId]!.add(item);
      }

      // 2. CREATE SEPARATE ORDERS FOR EACH SELLER
      for (var sellerId in orderGroups.keys) {
        List<Map<String, dynamic>> sellerItems = orderGroups[sellerId]!;
        
        // Calculate total for this specific seller's part of the order
        double sellerTotal = sellerItems.fold(0, (sum, item) {
          return sum + ((item['Price'] ?? 0) * (item['quantity'] ?? 1));
        });

        String orderId = "${timestamp}_$sellerId"; // Unique ID per seller-order

        // Data Payload
        Map<String, dynamic> orderData = {
          'orderId': orderId,
          'buyerId': userId,
          'sellerId': sellerId,
          'items': sellerItems,
          'address': address,
          'totalPrice': sellerTotal,
          'orderStatus': 'Pending', // Default status
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'product', // To distinguish from services/leads if needed
        };

        // --- WRITE 1: To the USER'S history ---
        DocumentReference userOrderRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(orderId);
        
        batch.set(userOrderRef, orderData);

        // --- WRITE 2: To the SELLER'S Dashboard ---
        // We flatten the items for the seller dashboard list if needed, 
        // or just send the full object. 
        // NOTE: Your AdminHome expects a list of documents. 
        // Ideally, we create ONE document per order on the admin side too.
        
        DocumentReference sellerOrderRef = FirebaseFirestore.instance
            .collection('Admin')
            .doc(sellerId)
            .collection('orders')
            .doc(orderId);

        // Add a field so the Seller knows which User doc to update later
        Map<String, dynamic> sellerViewData = {
          ...orderData,
          'consolidatedOrderId': orderId, // Link back to User's order ID
          // Add simplified fields for the Admin List View if necessary
          'productName': sellerItems.length == 1 
              ? sellerItems[0]['Name'] 
              : "${sellerItems[0]['Name']} + ${sellerItems.length - 1} more",
          'productImage': sellerItems[0]['Image'],
          'quantity': sellerItems.length == 1 
              ? sellerItems[0]['quantity'] 
              : sellerItems.length, // Simplified count
        };

        batch.set(sellerOrderRef, sellerViewData);
      }

      // 3. COMMIT & CLEAR CART
      await batch.commit();
      cartProvider.clearCart(); // Clear local cart

      return "Order placed successfully!";
    } catch (e) {
      return "Failed to place order: $e";
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