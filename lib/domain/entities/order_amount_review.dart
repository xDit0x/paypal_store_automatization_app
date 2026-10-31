/// Importe que se pagaría ahora mismo por un pedido.
///
/// El catálogo del proveedor puede cambiar entre crear el pedido y pagarlo:
/// el servidor recalcula con el precio vigente y avisa si el total cambió.
class OrderAmountReview {
  final double total;
  final double previousTotal;
  final bool changed;

  const OrderAmountReview({
    required this.total,
    required this.previousTotal,
    this.changed = false,
  });
}
