class Supplier {
  final String id;
  final String name;
  final String? paypalEmail;
  final String? category;
  final String? logoUrl;
  final bool active;

  const Supplier({
    required this.id,
    required this.name,
    this.paypalEmail,
    this.category,
    this.logoUrl,
    this.active = true,
  });
}
