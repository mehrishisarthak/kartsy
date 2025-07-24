import 'package:ecommerce_shop/utils/database.dart';
import 'package:flutter/foundation.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> get cart => _cart;

  void setCart(List<Map<String, dynamic>> items) {
    _cart
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  // ✅ UNIFIED AND SAFE addToCart METHOD
  Future<void> addToCart(String userId, Map<String, dynamic> product) async {
    final existingItemIndex = _cart.indexWhere((item) => item['id'] == product['id']);

    if (existingItemIndex != -1) {
      // Item already exists, so we safely increment its quantity.
      final existingItem = _cart[existingItemIndex];
      final currentQuantity = existingItem['quantity'] as int? ?? 0;
      existingItem['quantity'] = currentQuantity + 1;
    } else {
      // Item is new, add it to the list with quantity 1.
      final newItem = {
        ...product, // Copies all data from the product
        'quantity': 1,  // Ensures quantity is always present
      };
      _cart.add(newItem);
    }

    // Notify listeners to update the UI
    notifyListeners();

    // Sync the change with the database
    await DatabaseMethods().addToCart(userId, product);
  }

  void updateQuantity(String productId, int delta) {
    final idx = _cart.indexWhere((it) => it['id'] == productId);
    if (idx != -1) {
      final current = _cart[idx]['quantity'] as int? ?? 0;
      final updated = current + delta;

      if (updated <= 0) {
        _cart.removeAt(idx);
      } else {
        _cart[idx]['quantity'] = updated;
      }
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((it) => it['id'] == productId);
    notifyListeners();
  }

  void addItemAt(int index, Map<String, dynamic> item) {
    if (index < 0 || index > _cart.length) {
      _cart.add(item);
    } else {
      _cart.insert(index, item);
    }
    notifyListeners();
  }

  double getTotalPrice() {
    return _cart.fold<double>(0, (sum, item) {
      final price = (item['Price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (item['quantity'] as int?) ?? 0;
      return sum + (price * quantity);
    });
  }
  
  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}