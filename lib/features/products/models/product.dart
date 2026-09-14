class Product {
  final String id;
  final String name;
  final String description;
  final int price; // in cents (e.g. 999 = $9.99)
  final String imageUrl;
  final String category;
  final int totalStock;
  final int availableStock;
  final bool isOutOfStock;
  final bool isLowStock;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.totalStock,
    required this.availableStock,
    required this.isOutOfStock,
    required this.isLowStock,
  });

  String get formattedPrice => '\$${(price / 100).toStringAsFixed(2)}';

  String get stockStatusLabel {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Only $availableStock left!';
    return 'In Stock ($availableStock)';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final availableStock = json['availableStock'] as int? ?? 0;
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      totalStock: json['totalStock'] as int? ?? availableStock,
      availableStock: availableStock,
      isOutOfStock: json['isOutOfStock'] as bool? ?? (availableStock <= 0),
      isLowStock: json['isLowStock'] as bool? ?? (availableStock > 0 && availableStock <= 3),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'totalStock': totalStock,
      'availableStock': availableStock,
      'isOutOfStock': isOutOfStock,
      'isLowStock': isLowStock,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    String? imageUrl,
    String? category,
    int? totalStock,
    int? availableStock,
    bool? isOutOfStock,
    bool? isLowStock,
  }) {
    final newStock = availableStock ?? this.availableStock;
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      totalStock: totalStock ?? this.totalStock,
      availableStock: newStock,
      isOutOfStock: isOutOfStock ?? (newStock <= 0),
      isLowStock: isLowStock ?? (newStock > 0 && newStock <= 3),
    );
  }
}
