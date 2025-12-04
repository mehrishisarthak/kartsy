import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/add_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For numeric input formatter
import 'package:intl/intl.dart';

class AdminHomePage extends StatefulWidget {
  final String adminId;
  const AdminHomePage({super.key, required this.adminId});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // --- LOGIC: DELETE PRODUCT ---
  Future<void> _deleteProduct(String productId) async {
    try {
      // We use a Batch to ensure it deletes from BOTH collections or NEITHER
      final batch = FirebaseFirestore.instance.batch();

      // 1. Delete from Global Products
      final globalRef = FirebaseFirestore.instance.collection('products').doc(productId);
      batch.delete(globalRef);

      // 2. Delete from Admin's Personal Listings
      final adminRef = FirebaseFirestore.instance
          .collection('Admin')
          .doc(widget.adminId)
          .collection('listings')
          .doc(productId);
      batch.delete(adminRef);

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product deleted successfully"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting product: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- LOGIC: UPDATE INVENTORY ---
  Future<void> _updateInventory(String productId, int newQuantity) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update Global Products
      final globalRef = FirebaseFirestore.instance.collection('products').doc(productId);
      batch.update(globalRef, {'inventory': newQuantity});

      // 2. Update Admin's Personal Listings
      final adminRef = FirebaseFirestore.instance
          .collection('Admin')
          .doc(widget.adminId)
          .collection('listings')
          .doc(productId);
      batch.update(adminRef, {'inventory': newQuantity});

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Stock updated to $newQuantity"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update stock: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // --- UI: SHOW DELETE CONFIRMATION ---
  void _showDeleteDialog(String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text("Are you sure you want to remove '$productName'? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(productId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // --- UI: SHOW UPDATE STOCK DIALOG ---
  void _showUpdateStockDialog(String productId, int currentStock) {
    final TextEditingController stockController = TextEditingController(text: currentStock.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Stock"),
        content: TextField(
          controller: stockController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: "New Quantity", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final int? newQty = int.tryParse(stockController.text.trim());
              if (newQty != null) {
                _updateInventory(productId, newQty);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Container(
            padding: const EdgeInsets.only(top: 40),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Admin Dashboard',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TabBar(
                  indicatorColor: colorScheme.primary,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
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
            _buildProductList(widget.adminId),
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
          backgroundColor: colorScheme.primary,
          icon: Icon(Icons.add, color: colorScheme.onPrimary),
          label: Text(
            "Add New Product",
            style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
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
          .orderBy('Name')
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
            final int inventory = int.tryParse(data['inventory']?.toString() ?? '0') ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Product Image
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
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['Name'] ?? 'Unnamed Product',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹${data['Price']?.toString() ?? 'N/A'}",
                            style: TextStyle(fontSize: 15, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          // Stock Indicator Row
                          InkWell(
                            onTap: () => _showUpdateStockDialog(doc.id, inventory),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, 
                                  size: 16, 
                                  color: inventory < 10 ? Colors.red : Colors.grey[700]
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Stock: $inventory",
                                  style: TextStyle(
                                    color: inventory < 10 ? Colors.red : Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 14, color: Colors.blue),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete Button
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                      onPressed: () => _showDeleteDialog(doc.id, data['Name'] ?? 'Product'),
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

  /// Builds the list of incoming orders.
  Widget _buildOrderList(String adminId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Admin')
          .doc(adminId)
          .collection('orders')
          .orderBy('timestamp', descending: true)
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
            final orderId = doc.id;
            final buyerId = data['buyerId'];
            final consolidatedOrderId = data['consolidatedOrderId']; 

            // FIX: Safe Calculation for Price
            final double price = (data['productPrice'] as num?)?.toDouble() ?? 0.0;
            final int quantity = (data['quantity'] as num?)?.toInt() ?? 1;
            final double total = price * quantity;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
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
                      subtitle: Text("Qty: $quantity  |  Total: ₹${total.toStringAsFixed(2)}"),
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
                              _buildStatusDropdown(orderId, buyerId, data['orderStatus'] ?? 'Pending', consolidatedOrderId),
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

  Widget _buildStatusDropdown(String orderId, String buyerId, String currentStatus, String? consolidatedOrderId) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: currentStatus,
        underline: const SizedBox(),
        items: ['Pending', 'Shipped', 'Delivered', 'Cancelled']
            .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
                ))
            .toList(),
        onChanged: (newStatus) {
          if (newStatus != null && consolidatedOrderId != null) {
            _updateOrderStatus(orderId, buyerId, newStatus, consolidatedOrderId);
          }
        },
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String buyerId, String newStatus, String consolidatedOrderId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      // 1. Update Admin Order
      final adminOrderRef = firestore
          .collection('Admin')
          .doc(widget.adminId)
          .collection('orders')
          .doc(orderId);
      batch.update(adminOrderRef, {'orderStatus': newStatus});

      // 2. Update User Order (Using consolidatedOrderId)
      final userOrderRef = firestore
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(consolidatedOrderId);
      batch.update(userOrderRef, {'orderStatus': newStatus});

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order status updated!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}