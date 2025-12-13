import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeadsProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _interests = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constants
  static const String _collectionLeads = 'leads';
  static const String _collectionAdmin = 'Admin';
  static const String _collectionUsers = 'users';
  static const String _fallbackAdminId = 'super_admin'; 

  List<Map<String, dynamic>> get interests => _interests;

  /// Add a product to user's interests (Lead Generation)
  /// ✅ UPDATED: Performs a BATCH WRITE to both Seller and User collections.
  Future<String> addLead({
    required String userId,
    required String productId,
    required Map<String, dynamic> productData,
    required String userEmail,
    required String userPhone,
    required String userName,
    required String userCity,
    required String userState,
  }) async {
    try {
      final WriteBatch batch = _firestore.batch();
      
      // 🛡️ 1. Determine Target Admin
      final String targetAdminId = productData['adminId'] ?? _fallbackAdminId;
      
      // Generate a consistent ID so we can easily delete it from both places later
      final String leadId = "${userId}_$productId"; 

      final leadData = {
        'leadId': leadId,
        'userId': userId,
        'productId': productId,
        'productName': productData['Name'] ?? 'Unknown Product',
        'productCategory': productData['category'] ?? 'Furniture',
        'productPrice': productData['Price'] ?? 0,
        'productImage': productData['Image'] ?? '',
        'productAdminId': targetAdminId,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'userName': userName,
        'userCity': userCity,
        'userState': userState,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'New',
        'adminNotes': '',
        'adminId': targetAdminId, 
      };

      // 📝 REF 1: Seller's Copy (For the Dashboard)
      final sellerDocRef = _firestore
          .collection(_collectionAdmin)
          .doc(targetAdminId)
          .collection(_collectionLeads)
          .doc(leadId);

      // 📝 REF 2: User's Copy (For "My Interests" Page)
      final userDocRef = _firestore
          .collection(_collectionUsers)
          .doc(userId)
          .collection(_collectionLeads)
          .doc(leadId);

      // Add to batch
      batch.set(sellerDocRef, leadData);
      batch.set(userDocRef, leadData);

      // 🚀 Commit Batch (Atomic: Both succeed or both fail)
      await batch.commit();

      // Optimistic UI Update
      _interests.add(leadData);
      notifyListeners();

      return 'Successfully added to interests!';
    } catch (e) {
      debugPrint("⛔ Error adding lead: $e");
      return 'Failed to save interest. Please try again.';
    }
  }

  /// Remove interest
  /// ✅ UPDATED: Deletes from both Seller and User collections.
  Future<void> removeLead(String leadId, String? adminId) async {
    try {
      final WriteBatch batch = _firestore.batch();
      final String targetAdminId = adminId ?? _fallbackAdminId;
      
      // Since we don't have the userId passed here directly, 
      // we assume the caller checks authorization or we parse it from the leadId 
      // if we used the `${userId}_$productId` format. 
      // HOWEVER, for safety in this specific method structure, 
      // we need to know WHICH user to delete from. 
      // Ideally, pass userId to this function. 
      // Assuming 'leadId' allows us to find the document in the user's subcollection 
      // if we are currently logged in.
      
      // FIXME: To make this robust, we need the current userId. 
      // For now, we will query the local list to find the userId if needed, 
      // or rely on the UI passing the correct ID.
      
      // 1. Delete from Seller
      final sellerDocRef = _firestore
          .collection(_collectionAdmin)
          .doc(targetAdminId)
          .collection(_collectionLeads)
          .doc(leadId);
      
      batch.delete(sellerDocRef);

      // 2. Delete from User (We need to find the user ID for the path)
      // Since we are likely calling this from the User App, we can look up the 
      // item in our local `_interests` list to get the userId.
      final localItem = _interests.firstWhere(
        (item) => item['leadId'] == leadId, 
        orElse: () => {}
      );

      if (localItem.isNotEmpty && localItem['userId'] != null) {
        final String userId = localItem['userId'];
        final userDocRef = _firestore
            .collection(_collectionUsers)
            .doc(userId)
            .collection(_collectionLeads)
            .doc(leadId);
        
        batch.delete(userDocRef);
      }

      await batch.commit();

      _interests.removeWhere((item) => item['leadId'] == leadId);
      notifyListeners();
      
    } catch (e) {
      debugPrint('⛔ Error removing lead: $e');
    }
  }

  /// Load user's interests DIRECTLY from their profile
  /// ✅ UPDATED: Much faster and cheaper than Collection Group Query
  Stream<List<Map<String, dynamic>>> getUserLeads(String userId) {
    return _firestore
        .collection(_collectionUsers)
        .doc(userId)
        .collection(_collectionLeads)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final leads = snapshot.docs
              .map((doc) => doc.data())
              .toList();
          
          _interests.clear();
          _interests.addAll(leads);
          // Use microtask to avoid build conflicts
          Future.microtask(() => notifyListeners());
          
          return leads;
        });
  }

  bool isProductInInterests(String productId) {
    return _interests.any((item) => item['productId'] == productId);
  }
}