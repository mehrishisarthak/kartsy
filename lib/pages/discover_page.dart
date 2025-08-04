import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/stream_builders/vertical_stream_builder.dart';
import 'package:flutter/material.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Products'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildSearchField(),
            ),
            const SizedBox(height: 24),
            _buildInfoSection(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "All Products",
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            
            // Note: Wrapping a ListView/GridView inside a SingleChildScrollView
            // can cause performance issues with very long lists.
            // For now, this is the simplest stable approach.
            VerticalProductsList(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: "Search products...",
        prefixIcon: Icon(Icons.search, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildInfoCard(icon: Icons.local_shipping_outlined, text: "Fast Delivery"),
          const SizedBox(width: 16),
          _buildInfoCard(icon: Icons.verified_user_outlined, text: "Secure Payments"),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(text, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
