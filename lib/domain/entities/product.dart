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
}
