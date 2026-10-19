import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/invoice.dart';

abstract class InvoiceRepository {
  Future<Either<String, Invoice?>> getByOrder(String orderId);
}
