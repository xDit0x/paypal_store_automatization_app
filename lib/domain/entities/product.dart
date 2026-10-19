class Product {
  final String id;
  final String uid;
  final String supplierId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final int stock;
  final int lowStockThreshold;
  final String unit;
  final String? imageUrl;
  final bool active;

  const Product({
    required this.id,
    required this.uid,
    required this.supplierId,
    required this.name,
    this.description,
    required this.price,
    this.currency = 'EUR',
    required this.stock,
    required this.lowStockThreshold,
    this.unit = 'unidad',
    this.imageUrl,
    this.active = true,
  });

  bool get isLowStock => stock <= lowStockThreshold;

  int get suggestedReorderQty {
    final missing = lowStockThreshold - stock;
    return missing >= 0 ? missing + 1 : 1;
  }

  Product copyWith({
    String? name,
    String? description,
    double? price,
    String? currency,
    int? stock,
    int? lowStockThreshold,
    String? unit,
    String? imageUrl,
    bool? active,
  }) {
    return Product(
      id: id,
      uid: uid,
      supplierId: supplierId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      active: active ?? this.active,
    );
  }
}
