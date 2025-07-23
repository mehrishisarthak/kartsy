import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/add_product.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminHomePage extends StatefulWidget {
  final String adminId;
  const AdminHomePage({super.key, required this.adminId});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // The number of tabs
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5F8),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(140), // Increased height for tabs
          child: Container(
            padding: const EdgeInsets.only(top: 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.admin_panel_settings_outlined, color: Colors.blue, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const TabBar(
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(icon: Icon(Icons.storefront), text: "Your Listings"),
                    Tab(icon: Icon(Icons.shopping_bag_outlined), text: "New Orders"),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Content for "Your Listings" tab
            _buildProductList(widget.adminId),
            // Content for "New Orders" tab
            _buildOrderList(widget.adminId),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddProduct(adminID: widget.adminId)),
            );
          },
          backgroundColor: Colors.blue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Add New Product",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  /// Builds the list of product listings for the admin.
  Widget _buildProductList(String adminId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Admin')
          .doc(adminId)
          .collection('listings')
          .orderBy('Name') // Sort alphabetically
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error loading listings"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.docs;
        if (products.isEmpty) {
          return const Center(
            child: Text("You haven't listed any products yet.", style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final doc = products[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['Image'] ?? '',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['Name'] ?? 'Unnamed Product', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("₹${data['Price']?.toString() ?? 'N/A'}", style: TextStyle(fontSize: 15, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        // TODO: Implement delete product logic with confirmation dialog
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the list of incoming orders for the admin.
  Widget _buildOrderList(String adminId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Admin')
          .doc(adminId)
          .collection('orders')
          .orderBy('timestamp', descending: true) // Show newest orders first
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error loading orders"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;
        if (orders.isEmpty) {
          return const Center(
            child: Text("You have no new orders.", style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final doc = orders[index];
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['productImage'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                           errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
                        ),
                      ),
                      title: Text(data['productName'] ?? 'Unknown Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Qty: ${data['quantity'] ?? 1}  |  Total: ₹${(data['productPrice'] ?? 0) * (data['quantity'] ?? 1)}"),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Order Status:", style: TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              _buildStatusDropdown(doc.id, data['orderStatus'] ?? 'Pending'),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               Text("Order Date:", style: TextStyle(color: Colors.grey.shade600)),
                               const SizedBox(height: 4),
                               Text(
                                timestamp != null ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp) : 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                               ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Dropdown for updating order status.
  Widget _buildStatusDropdown(String orderId, String currentStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: currentStatus,
        underline: const SizedBox(), // Hides the default underline
        items: ['Pending', 'Shipped', 'Delivered', 'Cancelled']
            .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
                ))
            .toList(),
        onChanged: (newStatus) {
          if (newStatus != null) {
            _updateOrderStatus(orderId, newStatus);
          }
        },
      ),
    );
  }

  /// Updates the order status in Firestore.
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('Admin')
          .doc(widget.adminId)
          .collection('orders')
          .doc(orderId)
          .update({'orderStatus': newStatus});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order status updated!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update status: $e"), backgroundColor: Colors.red),
      );
    }
  }
}
