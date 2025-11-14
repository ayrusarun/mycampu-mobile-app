import 'dart:async';
import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../models/store_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final StoreService _storeService = StoreService();

  Product? _product;
  UserBalance? _userBalance;
  Cart? _cart;

  bool _isLoadingProduct = false;
  bool _isLoadingBalance = false;
  bool _isAddingToCart = false;
  bool _isAddingToWishlist = false;

  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadProduct(),
      _loadBalance(),
      _loadCart(),
    ]);
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoadingProduct = true);
    try {
      final product = await _storeService.getProduct(widget.productId);
      setState(() => _product = product);
    } catch (e) {
      _showErrorSnackBar('Failed to load product: $e');
    } finally {
      setState(() => _isLoadingProduct = false);
    }
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoadingBalance = true);
    try {
      final balance = await _storeService.getBalance();
      setState(() => _userBalance = balance);
    } catch (e) {
      _showErrorSnackBar('Failed to load balance: $e');
    } finally {
      setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _loadCart() async {
    try {
      final cart = await _storeService.getCart();
      setState(() => _cart = cart);
    } catch (e) {
      // Cart might be empty, which is fine
    }
  }

  Future<void> _addToCart() async {
    if (_product == null) return;

    setState(() => _isAddingToCart = true);
    try {
      await _storeService.addToCart(_product!.id, _quantity);
      _showSuccessSnackBar('Added to cart successfully!');
      await _loadCart(); // Refresh cart
    } catch (e) {
      _showErrorSnackBar('Failed to add to cart: $e');
    } finally {
      setState(() => _isAddingToCart = false);
    }
  }

  Future<void> _addToWishlist() async {
    if (_product == null) return;

    setState(() => _isAddingToWishlist = true);
    try {
      await _storeService.addToWishlist(_product!.id);
      _showSuccessSnackBar('Added to wishlist successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to add to wishlist: $e');
    } finally {
      setState(() => _isAddingToWishlist = false);
    }
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

  bool get _canAfford {
    if (_product == null || _userBalance == null) return false;
    return _userBalance!.currentPoints >= (_product!.pointsPrice * _quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      body: _isLoadingProduct
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? _buildErrorState()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductImage(),
                      _buildProductInfo(),
                      _buildQuantitySelector(),
                      _buildPriceInfo(),
                      _buildActionButtons(),
                      _buildBalanceInfo(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Product not found',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: _product!.imageUrl != null
          ? Image.network(
              _product!.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholderImage(),
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.image,
          size: 80,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _product!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isAddingToWishlist ? null : _addToWishlist,
                icon: _isAddingToWishlist
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.favorite_border),
                color: Colors.red.shade400,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              _product!.category,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _product!.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Stock: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                '${_product!.stockQuantity} available',
                style: TextStyle(
                  fontSize: 16,
                  color: _product!.isInStock
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(
            'Quantity:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove),
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _quantity < (_product!.stockQuantity)
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add),
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.stars,
            color: Colors.amber.shade600,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Cost',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${_product!.pointsPrice * _quantity} points',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _canAfford
                        ? Colors.amber.shade700
                        : Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (!_canAfford)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Insufficient Points',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: (_product!.isInStock && _canAfford && !_isAddingToCart)
                  ? _addToCart
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isAddingToCart
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.shopping_cart),
              label: Text(
                _isAddingToCart
                    ? 'Adding to Cart...'
                    : !_product!.isInStock
                        ? 'Out of Stock'
                        : !_canAfford
                            ? 'Insufficient Points'
                            : 'Add to Cart',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple.shade600,
                side: BorderSide(color: Colors.purple.shade600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(
                'View Cart ${_cart != null && _cart!.totalItems > 0 ? '(${_cart!.totalItems})' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Balance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current Points: ${_userBalance?.currentPoints ?? 0}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              if (!_isLoadingBalance)
                IconButton(
                  onPressed: _loadBalance,
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          if (_canAfford && _userBalance != null)
            Text(
              'After purchase: ${_userBalance!.currentPoints - (_product!.pointsPrice * _quantity)} points',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
