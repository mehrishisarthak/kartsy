import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/add_product.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  final String adminId;
  const AdminHomePage({super.key, required this.adminId});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  @override
  Widget build(BuildContext context) {
    final adminId = widget.adminId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.blue, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          const Text("Your Listings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildProductList(adminId),

          const SizedBox(height: 30),
          const Text("Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildOrderList(adminId),

          const SizedBox(height: 80),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 55,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddProduct(adminID: widget.adminId)),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Add Product",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Product Listings
  Widget _buildProductList(String adminId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Admin') // retained 'Admin'
          .doc(adminId)
          .collection('listings')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error loading listings");
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final products = snapshot.data!.docs;
        if (products.isEmpty) return const Text("No listings yet");

        return Column(
          children: products.map((doc) {
            final data = doc.data();
            if (data == null || data is! Map<String, dynamic>) return const SizedBox.shrink();

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: (data['Image'] != null && data['Image'].toString().isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          data['Image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.image, size: 50),
                title: Text(data['Name'] ?? 'Unnamed Product'),
                subtitle: Text("₹${data['Price']?.toString() ?? 'N/A'}"),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Order Listings
  Widget _buildOrderList(String adminId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Admin') // retained 'Admin'
          .doc(adminId)
          .collection('orders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error loading orders");
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final orders = snapshot.data!.docs;
        if (orders.isEmpty) return const Text("No orders yet");

        return Column(
          children: orders.map((doc) {
            final data = doc.data();
            if (data == null || data is! Map<String, dynamic>) return const SizedBox.shrink();

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: Text("Order: ${data['orderName'] ?? 'Unknown'}"),
                subtitle: Text("Qty: ${data['quantity'] ?? 0} | Buyer: ${data['buyerName'] ?? 'Unknown'}"),
                trailing: Text("₹${data['total']?.toString() ?? '0'}"),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
