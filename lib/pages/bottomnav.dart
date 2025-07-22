import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:ecommerce_shop/pages/home.dart';
import 'package:ecommerce_shop/pages/cart.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:flutter/material.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int currentIndex = 0;
  String? userId;
  bool isLoading = true;

  // 1. Define the pages list here, outside the build method.
  // This ensures the page widgets are created only once.
  final List<Widget> pages = [
    const HomeScreen(),
    const CartPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await SharedPreferenceHelper().getUserID();
    if (mounted) {
      setState(() {
        userId = id;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // 2. Use IndexedStack as the body.
      // It keeps all pages in the widget tree, preserving their state.
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent, // Often looks better with IndexedStack
        color: Colors.blue,
        buttonBackgroundColor: Colors.blue,
        height: 60,
        index: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          Icon(Icons.home_outlined, size: 30, color: Colors.white),
          Icon(Icons.shopping_cart_outlined, size: 30, color: Colors.white),
        ],
      ),
    );
  }
}