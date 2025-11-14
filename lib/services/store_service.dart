import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store_model.dart';
import '../config/app_config.dart';

class StoreService {
  static const String baseUrl = AppConfig.baseUrl;

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Product Management

  /// Get all products with filtering and pagination
  Future<List<Product>> getProducts({
    int skip = 0,
    int limit = 20,
    String? category,
    String? search,
    int? minPrice,
    int? maxPrice,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/rewards/store/products?skip=$skip&limit=$limit';

      if (category != null) url += '&category=${Uri.encodeComponent(category)}';
      if (search != null && search.isNotEmpty)
        url += '&search=${Uri.encodeComponent(search)}';
      if (minPrice != null) url += '&min_price=$minPrice';
      if (maxPrice != null) url += '&max_price=$maxPrice';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['products'] ?? [];
        return data.map((product) => Product.fromJson(product)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  /// Get a specific product by ID
  Future<Product> getProduct(int productId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/store/products/$productId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data);
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  // Category Management

  /// Get all product categories with counts
  Future<List<Category>> getCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/store/categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((category) => Category.fromJson(category)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  // Cart Management

  /// Get user's current cart
  Future<Cart> getCart() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/store/cart'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Cart.fromJson(data);
      } else {
        throw Exception('Failed to load cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load cart: $e');
    }
  }

  /// Add item to cart
  Future<void> addToCart(int productId, int quantity) async {
    try {
      final headers = await _getHeaders();
      final body = CartItemAdd(productId: productId, quantity: quantity);

      final response = await http.post(
        Uri.parse('$baseUrl/rewards/store/cart/add'),
        headers: headers,
        body: json.encode(body.toJson()),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to add item to cart');
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  /// Update cart item quantity
  Future<void> updateCartItem(int itemId, int quantity) async {
    try {
      final headers = await _getHeaders();
      final body = CartItemUpdate(quantity: quantity);

      final response = await http.put(
        Uri.parse('$baseUrl/rewards/store/cart/update/$itemId'),
        headers: headers,
        body: json.encode(body.toJson()),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update cart item');
      }
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(int itemId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/rewards/store/cart/remove/$itemId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['detail'] ?? 'Failed to remove item from cart');
      }
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/rewards/store/cart/clear'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to clear cart');
      }
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Checkout and Orders

  /// Process cart checkout
  Future<Order> checkout({String? shippingAddress, String? notes}) async {
    try {
      final headers = await _getHeaders();
      final body = CheckoutRequest(
        shippingAddress: shippingAddress,
        notes: notes,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/rewards/store/checkout'),
        headers: headers,
        body: json.encode(body.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to process checkout');
      }
    } catch (e) {
      throw Exception('Failed to process checkout: $e');
    }
  }

  /// Get user's order history
  Future<List<Order>> getOrders({int skip = 0, int limit = 20}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/store/orders?skip=$skip&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> orders = data['orders'];
        return orders.map((order) => Order.fromJson(order)).toList();
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  /// Get specific order details
  Future<Order> getOrder(int orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/store/orders/$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data);
      } else {
        throw Exception('Failed to load order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load order: $e');
    }
  }

  // Balance Management

  /// Get user's current point balance and summary
  Future<UserBalance> getBalance() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/store/balance'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserBalance.fromJson(data);
      } else {
        throw Exception('Failed to load balance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load balance: $e');
    }
  }

  /// Get user's point transaction history
  Future<List<PointTransaction>> getBalanceHistory(
      {int skip = 0, int limit = 50}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
            '$baseUrl/rewards/store/balance/history?skip=$skip&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((transaction) => PointTransaction.fromJson(transaction))
            .toList();
      } else {
        throw Exception(
            'Failed to load balance history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load balance history: $e');
    }
  }

  // Wishlist Management

  /// Get user's wishlist
  Future<List<WishlistItem>> getWishlist() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/store/wishlist'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => WishlistItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load wishlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load wishlist: $e');
    }
  }

  /// Add product to wishlist
  Future<void> addToWishlist(int productId) async {
    try {
      final headers = await _getHeaders();
      final body = WishlistAdd(productId: productId);

      final response = await http.post(
        Uri.parse('$baseUrl/rewards/store/wishlist/add'),
        headers: headers,
        body: json.encode(body.toJson()),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to add to wishlist');
      }
    } catch (e) {
      throw Exception('Failed to add to wishlist: $e');
    }
  }

  /// Remove product from wishlist
  Future<void> removeFromWishlist(int productId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/rewards/store/wishlist/remove/$productId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['detail'] ?? 'Failed to remove from wishlist');
      }
    } catch (e) {
      throw Exception('Failed to remove from wishlist: $e');
    }
  }
}
