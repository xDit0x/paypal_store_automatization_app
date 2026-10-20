import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/invoice.dart';

abstract class InvoiceRepository {
  Future<Either<AppError, Invoice?>> getByOrder(String orderId);
}
