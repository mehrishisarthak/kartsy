import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
Future<void> addProduct(Map<String, dynamic> productData, String categoryName, String adminId) async {
  final firestore = FirebaseFirestore.instance;
  final String productId = productData['id'];

  // Add to category-specific collection using product ID
  await firestore.collection(categoryName).doc(productId).set(productData);

  // Add to global 'products' collection using same product ID
  await firestore.collection('products').doc(productId).set({
    ...productData,
    'category': categoryName,
    'adminId': adminId,
  });

  // Add to admin's personal listing using same product ID
  await firestore
      .collection('Admin')
      .doc(adminId)
      .collection('listings')
      .doc(productId)
      .set(productData);
}


Future <Stream<QuerySnapshot>> getListings(String category) async{
return FirebaseFirestore.instance.collection(category).snapshots();
}

Future<void> addToCart(String userId, Map<String, dynamic> product) async {
  final cartRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('cart')
      .doc(product['id']); // or any unique ID

  final doc = await cartRef.get();

  if (doc.exists) {
    // Already in cart → update quantity
    await cartRef.update({
      'quantity': FieldValue.increment(1),
    });
  } else {
    // Not in cart → add new
    await cartRef.set({
      'name': product['Name'],
      'price': product['Price'],
      'image': product['Image'],
      'quantity': 1,
    });
  }
}


Future<String> fetchAdminId(String username, String password) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('Admin')
      .where('username', isEqualTo: username.trim().toLowerCase())
      .where('password', isEqualTo: password.trim()) // ideally hashed
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    return querySnapshot.docs.first.id;
  }

  return ""; // Return empty string if not found
}
}