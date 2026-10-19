import 'package:store_automatization_app/domain/entities/store.dart';

class StoreModel {
  const StoreModel._();

  static Store fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String? ?? 'Mi tienda',
      currency: map['currency'] as String? ?? 'EUR',
      paypalMerchantEmail: map['paypal_merchant_email'] as String?,
      notificationEmail: map['notification_email'] as String?,
    );
  }
}
