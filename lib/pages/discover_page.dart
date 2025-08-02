import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/stream_builders/vertical_stream_builder.dart';
import 'package:ecommerce_shop/widget/support_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      "All Products",
                      style: AppWidget.boldTextStyle().copyWith(fontSize: 22),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  VerticalProductsList(
                    stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper methods for building the page-specific UI ---

  Widget _buildHeader() {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style: GoogleFonts.lato(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                children: const [
                  TextSpan(text: "Discover Products\nWith "),
                  TextSpan(
                    text: "Kartsy",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search products...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
        style: AppWidget.lightTextStyle(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Text(text, style: AppWidget.boldTextStyle().copyWith(color: Colors.black87)),
        ],
      ),
    );
  }
}
