class SaleRecord {
  final DateTime date;
  final int quantity;
  final double price;
  final double total;
  final String billNumber;

  SaleRecord({
    required this.date,
    required this.quantity,
    required this.price,
    required this.total,
    required this.billNumber,
  });
}