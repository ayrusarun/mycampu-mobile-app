// Store/Marketplace models for the MyCampus app

class Product {
  final int id;
  final String name;
  final String description;
  final int pointsPrice;
  final String? imageUrl;
  final String category;
  final String status;
  final int stockQuantity;
  final int maxQuantityPerUser;
  final double originalPrice;
  final String? brand;
  final String? specifications;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool inStock;
  final bool canPurchase;
  final String? creatorName;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsPrice,
    this.imageUrl,
    required this.category,
    required this.status,
    required this.stockQuantity,
    required this.maxQuantityPerUser,
    required this.originalPrice,
    this.brand,
    this.specifications,
    this.createdAt,
    this.updatedAt,
    required this.inStock,
    required this.canPurchase,
    this.creatorName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      pointsPrice: json['points_required'],
      imageUrl: json['image_url'],
      category: json['category'],
      status: json['status'],
      stockQuantity: json['stock_quantity'],
      maxQuantityPerUser: json['max_quantity_per_user'] ?? 1,
      originalPrice: (json['original_price'] as num).toDouble(),
      brand: json['brand'],
      specifications: json['specifications'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      inStock: json['in_stock'] ?? true,
      canPurchase: json['can_purchase'] ?? true,
      creatorName: json['creator_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points_required': pointsPrice,
      'image_url': imageUrl,
      'category': category,
      'status': status,
      'stock_quantity': stockQuantity,
      'max_quantity_per_user': maxQuantityPerUser,
      'original_price': originalPrice,
      'brand': brand,
      'specifications': specifications,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'in_stock': inStock,
      'can_purchase': canPurchase,
      'creator_name': creatorName,
    };
  }

  bool get isInStock => inStock && stockQuantity > 0;
}

class Category {
  final String category;
  final String displayName;
  final int productCount;

  Category({
    required this.category,
    required this.displayName,
    required this.productCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      category: json['category'],
      displayName: json['display_name'],
      productCount: json['product_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'display_name': displayName,
      'product_count': productCount,
    };
  }

  // For backward compatibility
  String get name => displayName;
  int get id => category.hashCode;
}

class CartItem {
  final int id;
  final int productId;
  final String productName;
  final int pointsPrice;
  final String? imageUrl;
  final int quantity;
  final DateTime addedAt;
  final Product? product;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.pointsPrice,
    this.imageUrl,
    required this.quantity,
    required this.addedAt,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      pointsPrice: json['product_points'],
      imageUrl: json['product_image'],
      quantity: json['quantity'],
      addedAt: DateTime.parse(json['added_at']),
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }

  int get totalPoints => pointsPrice * quantity;
}

class Cart {
  final List<CartItem> items;
  final int totalItems;
  final int totalPoints;

  Cart({
    required this.items,
    required this.totalItems,
    required this.totalPoints,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      totalItems: json['total_items'],
      totalPoints: json['total_points'],
    );
  }

  bool get isEmpty => items.isEmpty;
}

class Order {
  final int id;
  final int userId;
  final int totalPoints;
  final OrderStatus status;
  final String? shippingAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.totalPoints,
    required this.status,
    this.shippingAddress,
    this.notes,
    required this.createdAt,
    this.deliveredAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      totalPoints: json['total_points'],
      status: OrderStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toUpperCase() ==
            json['status'].toUpperCase(),
      ),
      shippingAddress: json['shipping_address'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final int pointsPrice;
  final int quantity;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.pointsPrice,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      pointsPrice: json['points_per_item'],
      quantity: json['quantity'],
      imageUrl: json['image_url'],
    );
  }

  int get totalPoints => pointsPrice * quantity;
}

class UserBalance {
  final int currentPoints;
  final int totalEarned;
  final int totalSpent;
  final int pendingOrdersPoints;
  final int availableBalance;

  UserBalance({
    required this.currentPoints,
    required this.totalEarned,
    required this.totalSpent,
    required this.pendingOrdersPoints,
    required this.availableBalance,
  });

  factory UserBalance.fromJson(Map<String, dynamic> json) {
    return UserBalance(
      currentPoints: json['current_balance'],
      totalEarned: json['total_earned'],
      totalSpent: json['total_spent'],
      pendingOrdersPoints: json['pending_orders_points'],
      availableBalance: json['available_balance'],
    );
  }
}

class PointTransaction {
  final int id;
  final int points;
  final TransactionType type;
  final String description;
  final DateTime createdAt;
  final int? orderId;
  final int? rewardId;

  PointTransaction({
    required this.id,
    required this.points,
    required this.type,
    required this.description,
    required this.createdAt,
    this.orderId,
    this.rewardId,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'],
      points: json['points'],
      type: TransactionType.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toUpperCase() ==
            json['type'].toUpperCase(),
      ),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      orderId: json['order_id'],
      rewardId: json['reward_id'],
    );
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.earned:
        return 'Earned';
      case TransactionType.spent:
        return 'Spent';
      case TransactionType.refunded:
        return 'Refunded';
    }
  }
}

enum TransactionType { earned, spent, refunded }

class WishlistItem {
  final int id;
  final int productId;
  final String productName;
  final int pointsPrice;
  final String? imageUrl;
  final DateTime addedAt;
  final Product? product;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.pointsPrice,
    this.imageUrl,
    required this.addedAt,
    this.product,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      pointsPrice: json['points_price'],
      imageUrl: json['image_url'],
      addedAt: DateTime.parse(json['added_at']),
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }
}

// Request/Response models for API calls
class CartItemAdd {
  final int productId;
  final int quantity;

  CartItemAdd({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
    };
  }
}

class CartItemUpdate {
  final int quantity;

  CartItemUpdate({required this.quantity});

  Map<String, dynamic> toJson() {
    return {'quantity': quantity};
  }
}

class CheckoutRequest {
  final String? shippingAddress;
  final String? notes;

  CheckoutRequest({
    this.shippingAddress,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (shippingAddress != null) 'shipping_address': shippingAddress,
      if (notes != null) 'notes': notes,
    };
  }
}

class WishlistAdd {
  final int productId;

  WishlistAdd({required this.productId});

  Map<String, dynamic> toJson() {
    return {'product_id': productId};
  }
}
