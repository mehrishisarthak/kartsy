import 'package:ecommerce_shop/pages/cart.dart';
import 'package:ecommerce_shop/pages/home.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:flutter/material.dart';

// CHANGED: Standard naming convention
class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  // CHANGED: Standard createState implementation
  State<BottomBar> createState() => _BottomBarState();
}

// CHANGED: Standard State class naming
class _BottomBarState extends State<BottomBar> {
  int currentIndex = 0;
  // This list will be initialized once, later on.
  late final List<Widget> pages;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await SharedPreferenceHelper().getUserID();

    // CHANGED: Initialize the pages list here, only once.
    // It will now persist across rebuilds caused by tab switching.
    pages = [
      HomeScreen(userId: id),
      CartPage(userId: id),
    ];

    if (mounted) {
      setState(() {
        // We no longer need to set a userId variable here.
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
    
    // The 'pages' list is no longer defined here. It's now a class member
    // that has already been initialized.

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages, // Using the persistent list of pages
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 14,
        unselectedFontSize: 12,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}