import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/stream_builders/vertical_stream_builder.dart';
import 'package:ecommerce_shop/utils/database.dart';
import 'package:flutter/material.dart';

class CategoryProducts extends StatefulWidget {
  const CategoryProducts({super.key, required this.category});
  final String category;

  @override
  State<CategoryProducts> createState() => _CategoryProductsState();
}

class _CategoryProductsState extends State<CategoryProducts> {
  Stream<QuerySnapshot>? listings;

  getOnTheLoad() async {
    listings = await DatabaseMethods().getListings(widget.category);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    getOnTheLoad();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      // AppBar now uses the theme's AppBarTheme
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        title: Text(
          widget.category,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // The body will display the list of products
      body: VerticalProductsList(
        stream: listings ?? const Stream.empty(),
      ),
    );
  }
}
