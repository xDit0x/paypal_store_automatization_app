/// Importe que se pagaría ahora mismo por un pedido.
///
/// El catálogo del proveedor puede cambiar entre crear el pedido y pagarlo:
/// el servidor recalcula con el precio vigente y avisa si el total cambió.
/// Si el pedido está bloqueado por reglas de gasto, `blockedReason` tendrá el mensaje.
class OrderAmountReview {
  final double total;
  final double previousTotal;
  final bool changed;
  /// Razón por la que el pedido está bloqueado (null si no lo está).
  final String? blockedReason;

  const OrderAmountReview({
    required this.total,
    required this.previousTotal,
    this.changed = false,
    this.blockedReason,
  });
}
