import 'package:store_automatization_app/data/models/model_utils.dart';
import 'package:store_automatization_app/domain/entities/invoice.dart';

class InvoiceModel {
  const InvoiceModel._();

  static Invoice fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      number: map['number'] as String? ?? '',
      pdfUrl: map['pdf_url'] as String?,
      status: map['status'] as String? ?? 'pending',
      sentTo: map['sent_to'] as String?,
      sentAt: asDateTime(map['sent_at']),
    );
  }
}
