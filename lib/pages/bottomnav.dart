import 'package:ecommerce_shop/pages/cart.dart';
import 'package:ecommerce_shop/pages/home.dart';
import 'package:flutter/material.dart';

class BottomBar extends StatefulWidget {
  final String userId; // 1. Receive ID directly

  const BottomBar({
    super.key, 
    required this.userId
  });

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int currentIndex = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    // 2. Initialize pages immediately using widget.userId
    // No async/await, no isLoading, no SharedPreferences needed!
    pages = [
      HomeScreen(userId: widget.userId),
      CartPage(userId: widget.userId),
    ];
  }

  // 3. Handle Android Back Button behavior
  // If on Cart tab -> Go to Home. If on Home -> Close App.
  Future<bool> _onWillPop() async {
    if (currentIndex != 0) {
      setState(() {
        currentIndex = 0;
      });
      return false; // Don't close app
    }
    return true; // Close app
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use WillPopScope (or PopScope in newer Flutter versions) for back button logic
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // IndexedStack preserves the state of the tabs (scrolling position, etc.)
        body: IndexedStack(
          index: currentIndex,
          children: pages,
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
      ),
    );
  }
}