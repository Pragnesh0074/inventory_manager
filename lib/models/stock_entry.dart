class StockEntry {
  final String id;
  final int quantity;
  final String type; // 'addition' or 'sale'
  final DateTime dateTime;
  final String? note;

  StockEntry({
    required this.id,
    required this.quantity,
    required this.type,
    required this.dateTime,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'type': type,
      'dateTime': dateTime.toIso8601String(),
      'note': note,
    };
  }

  factory StockEntry.fromJson(Map<String, dynamic> json) {
    return StockEntry(
      id: json['id'],
      quantity: json['quantity'],
      type: json['type'],
      dateTime: DateTime.parse(json['dateTime']),
      note: json['note'],
    );
  }
}