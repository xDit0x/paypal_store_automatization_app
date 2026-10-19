import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/data/datasources/invoice_repository/supabase_invoice_datasource.dart';
import 'package:store_automatization_app/data/models/invoice_model.dart';
import 'package:store_automatization_app/domain/entities/invoice.dart';
import 'package:store_automatization_app/domain/repositories/invoice_repository/invoice_repository.dart';

class SupabaseInvoiceRepository implements InvoiceRepository {
  final SupabaseInvoiceDatasource _datasource;
  SupabaseInvoiceRepository(this._datasource);

  @override
  Future<Either<String, Invoice?>> getByOrder(String orderId) async {
    try {
      final row = await _datasource.getByOrder(orderId);
      return Right(row == null ? null : InvoiceModel.fromMap(row));
    } catch (error) {
      return Left('No se pudo cargar la factura: $error');
    }
  }
}
