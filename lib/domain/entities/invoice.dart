class Invoice {
  final String id;
  final String orderId;
  final String number;
  final String? pdfUrl;
  final String status;
  final String? sentTo;
  final DateTime? sentAt;

  const Invoice({
    required this.id,
    required this.orderId,
    required this.number,
    this.pdfUrl,
    this.status = 'pending',
    this.sentTo,
    this.sentAt,
  });
}
