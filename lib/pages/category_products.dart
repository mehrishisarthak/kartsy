import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/stream_builders/vertical_stream_builder.dart';
import 'package:ecommerce_shop/utils/database.dart';
import 'package:ecommerce_shop/widget/support_widget.dart';
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
    setState(() {});
  }

  @override
  void initState() {
    getOnTheLoad();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        title: Text(
          widget.category,
          style: AppWidget.boldTextStyle().copyWith(
            color: Colors.blue,
            fontSize: 24,
          ),
        ),
      ),
      body: VerticalProductsList(
        stream: listings ?? const Stream.empty(),
      ),
    );
  }
}
