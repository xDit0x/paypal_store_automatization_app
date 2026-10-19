class Store {
  final String id;
  final String ownerId;
  final String name;
  final String currency;
  final String? paypalMerchantEmail;
  final String? notificationEmail;

  const Store({
    required this.id,
    required this.ownerId,
    required this.name,
    this.currency = 'EUR',
    this.paypalMerchantEmail,
    this.notificationEmail,
  });
}
