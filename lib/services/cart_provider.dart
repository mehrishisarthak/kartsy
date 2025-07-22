import 'package:flutter/foundation.dart';

class CartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _cart = [];

  List<Map<String, dynamic>> get cart => _cart;

  void setCart(List<Map<String, dynamic>> items) {
    _cart
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  void addProduct(Map<String, dynamic> product) {
    final id = product['id'] as String;
    final index = _cart.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      _cart[index]['quantity'] = (_cart[index]['quantity'] as int) + 1;
    } else {
      final newProd = {
        'id': id,
        'name': product['Name'] ?? product['name'],
        'price': (product['Price'] ?? product['price']) as num,
        'image': product['Image'] ?? product['image'],
        'quantity': (product['quantity'] ?? 1) as int,
      };
      _cart.add(newProd.cast<String, dynamic>());
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int delta) {
    final idx = _cart.indexWhere((it) => it['id'] == productId);
    if (idx != -1) {
      final current = _cart[idx]['quantity'] as int;
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

  /// Adds an item back to the cart at a specific position.
  /// This is required for the "remove item" rollback functionality.
  void addItemAt(int index, Map<String, dynamic> item) {
    if (index < 0 || index > _cart.length) {
      _cart.add(item); // Add to end if index is invalid
    } else {
      _cart.insert(index, item);
    }
    notifyListeners();
  }

  double getTotalPrice() {
    return _cart.fold<double>(0, (sum, item) {
      final price = (item['price'] as num).toDouble();
      final quantity = item['quantity'] as int;
      return sum + price * quantity;
    });
  }
}