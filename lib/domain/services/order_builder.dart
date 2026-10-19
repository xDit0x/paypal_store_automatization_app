import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/order_item.dart';
import 'package:store_automatization_app/domain/entities/product.dart';

class DraftOrderLine {
  final String productUid;
  final int qty;

  const DraftOrderLine({required this.productUid, required this.qty});
}

class OrderBuilder {
  const OrderBuilder._();

  static Either<String, List<OrderItem>> buildItems({
    required List<DraftOrderLine> lines,
    required List<Product> products,
  }) {
    if (lines.isEmpty) {
      return const Left('El pedido no tiene líneas.');
    }

    final productsByUid = {for (final product in products) product.uid: product};
    final items = <OrderItem>[];

    for (final line in lines) {
      if (line.qty <= 0) {
        return Left('Cantidad inválida para ${line.productUid}.');
      }

      final product = productsByUid[line.productUid];
      if (product == null) {
        return Left('Producto no encontrado: ${line.productUid}.');
      }

      if (!product.active) {
        return Left('El producto ${product.name} no está activo.');
      }

      items.add(
        OrderItem(
          productUid: product.uid,
          name: product.name,
          qty: line.qty,
          unitPrice: product.price,
        ),
      );
    }

    return Right(items);
  }

  static double subtotal(List<OrderItem> items) {
    return items.fold(0, (sum, item) => sum + item.lineTotal);
  }

  static double total(List<OrderItem> items) => subtotal(items);
}
