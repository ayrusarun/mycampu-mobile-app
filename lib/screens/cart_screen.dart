import 'dart:async';
import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../models/store_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final StoreService _storeService = StoreService();
  final TextEditingController _shippingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Cart? _cart;
  UserBalance? _userBalance;

  bool _isLoadingCart = false;

  bool _isUpdating = false;
  bool _isProcessingCheckout = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _shippingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCart(),
      _loadBalance(),
    ]);
  }

  Future<void> _loadCart() async {
    setState(() => _isLoadingCart = true);
    try {
      final cart = await _storeService.getCart();
      setState(() => _cart = cart);
    } catch (e) {
      _showErrorSnackBar('Failed to load cart: $e');
    } finally {
      setState(() => _isLoadingCart = false);
    }
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await _storeService.getBalance();
      setState(() => _userBalance = balance);
    } catch (e) {
      _showErrorSnackBar('Failed to load balance: $e');
    }
  }

  Future<void> _updateQuantity(int itemId, int newQuantity) async {
    setState(() => _isUpdating = true);
    try {
      await _storeService.updateCartItem(itemId, newQuantity);
      await _loadCart(); // Refresh cart
    } catch (e) {
      _showErrorSnackBar('Failed to update quantity: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _removeItem(int itemId) async {
    setState(() => _isUpdating = true);
    try {
      await _storeService.removeFromCart(itemId);
      await _loadCart(); // Refresh cart
      _showSuccessSnackBar('Item removed from cart');
    } catch (e) {
      _showErrorSnackBar('Failed to remove item: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await _showConfirmDialog(
      'Clear Cart',
      'Are you sure you want to remove all items from your cart?',
    );

    if (confirmed) {
      setState(() => _isUpdating = true);
      try {
        await _storeService.clearCart();
        await _loadCart(); // Refresh cart
        _showSuccessSnackBar('Cart cleared successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to clear cart: $e');
      } finally {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _processCheckout() async {
    if (_cart == null || _cart!.isEmpty) return;

    final canAfford =
        (_userBalance?.availableBalance ?? 0) >= _cart!.totalPoints;
    if (!canAfford) {
      _showErrorSnackBar('Insufficient points to complete purchase');
      return;
    }

    setState(() => _isProcessingCheckout = true);
    try {
      await _storeService.checkout(
        shippingAddress: _shippingController.text.trim().isNotEmpty
            ? _shippingController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        _showSuccessSnackBar('Order placed successfully!');

        // Navigate to order details or orders list
        Navigator.pushReplacementNamed(context, '/orders');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to process checkout: $e');
    } finally {
      setState(() => _isProcessingCheckout = false);
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _canAfford =>
      (_userBalance?.availableBalance ?? 0) >= (_cart?.totalPoints ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Shopping Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_cart != null && !_cart!.isEmpty)
            TextButton(
              onPressed: _isUpdating ? null : _clearCart,
              child: Text(
                'Clear All',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ),
        ],
      ),
      body: _isLoadingCart
          ? const Center(child: CircularProgressIndicator())
          : _cart == null || _cart!.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    _buildBalanceCard(),
                    Expanded(
                      child: _buildCartItems(),
                    ),
                    _buildCheckoutSection(),
                  ],
                ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products from the marketplace',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/marketplace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Browse Marketplace'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Points',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_userBalance?.currentPoints ?? 0} pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadBalance,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _cart!.items.length,
      itemBuilder: (context, index) {
        final item = _cart!.items[index];
        return _buildCartItemCard(item);
      },
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderImage(),
                      ),
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 16),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: Colors.amber.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.pointsPrice} pts each',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quantity Controls
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _isUpdating
                                  ? null
                                  : item.quantity > 1
                                      ? () => _updateQuantity(
                                          item.id, item.quantity - 1)
                                      : () => _removeItem(item.id),
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(8),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  item.quantity > 1
                                      ? Icons.remove
                                      : Icons.delete_outline,
                                  size: 16,
                                  color: item.quantity > 1
                                      ? Colors.grey.shade600
                                      : Colors.red,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.symmetric(
                                  vertical:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _isUpdating
                                  ? null
                                  : () => _updateQuantity(
                                      item.id, item.quantity + 1),
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(8),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${item.totalPoints} pts',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Icon(
        Icons.image,
        size: 32,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shipping Address
            TextField(
              controller: _shippingController,
              decoration: InputDecoration(
                labelText: 'Shipping Address (Optional)',
                hintText: 'Enter your delivery address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Any special instructions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Total and Checkout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Total Items:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      Text(
                        '${_cart!.totalItems}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Total Cost:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.stars,
                            color: Colors.amber.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_cart!.totalPoints} pts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _canAfford
                                  ? Colors.black87
                                  : Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!_canAfford) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.red.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Insufficient points. You need ${_cart!.totalPoints - (_userBalance?.currentPoints ?? 0)} more points.',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Checkout Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (_canAfford && !_isProcessingCheckout && !_isUpdating)
                        ? _processCheckout
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessingCheckout
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : const Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
