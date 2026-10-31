class CatalogProduct {
  final String id;
  final String uid;
  final String supplierId;
  final String supplierName;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final int? stock;
  final int? lowStockThreshold;
  final bool inInventory;
  final String unit;
  final String? imageUrl;
  final bool active;

  const CatalogProduct({
    required this.id,
    required this.uid,
    required this.supplierId,
    required this.supplierName,
    required this.name,
    this.description,
    required this.price,
    this.currency = 'EUR',
    this.stock,
    this.lowStockThreshold,
    this.inInventory = false,
    this.unit = 'unidad',
    this.imageUrl,
    this.active = true,
  });
}
