import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartIconWithBadge extends StatefulWidget {
  final bool isActive;
  const CartIconWithBadge({super.key, required this.isActive});

  @override
  State<CartIconWithBadge> createState() => _CartIconWithBadgeState();
}

class _CartIconWithBadgeState extends State<CartIconWithBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  int _previousItemCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the previous item count
    _previousItemCount =
        Provider.of<CartProvider>(context, listen: false).cart.length;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final itemCount = cart.cart.length;

        // If a new item was added, trigger the animation
        if (itemCount > _previousItemCount) {
          _controller.forward(from: 0.0).then((_) => _controller.reverse());
        }
        _previousItemCount = itemCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(widget.isActive
                  ? Icons.shopping_cart
                  : Icons.shopping_cart_outlined),
            ),
            if (itemCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
