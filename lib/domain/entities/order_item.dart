class OrderItem {
  final String productUid;
  final String name;
  final int qty;
  final double unitPrice;

  const OrderItem({
    required this.productUid,
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  double get lineTotal => qty * unitPrice;
}
