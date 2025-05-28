class Transaction {
  final String id;
  final String itemId;
  final String itemName;
  final int quantity;
  final double price;
  final double totalAmount;
  final DateTime dateTime;
  final String type;

  Transaction({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.dateTime,
    required this.type,
  });

  // Convert Transaction to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'price': price,
      'total_amount': totalAmount,
      'date_time': dateTime.toIso8601String(),
      'type': type,
    };
  }

  // Create Transaction from database Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      itemId: map['item_id'] ?? '',
      itemName: map['item_name'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      price: map['price']?.toDouble() ?? 0.0,
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      dateTime: DateTime.parse(map['date_time'] ?? DateTime.now().toIso8601String()),
      type: map['type'] ?? '',
    );
  }

  // Convert Transaction to JSON (for API or file storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'price': price,
      'totalAmount': totalAmount,
      'dateTime': dateTime.toIso8601String(),
      'type': type,
    };
  }

  // Create Transaction from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      quantity: json['quantity']?.toInt() ?? 0,
      price: json['price']?.toDouble() ?? 0.0,
      totalAmount: json['totalAmount']?.toDouble() ?? 0.0,
      dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toIso8601String()),
      type: json['type'] ?? '',
    );
  }

  // Create a copy of the transaction with updated fields
  Transaction copyWith({
    String? id,
    String? itemId,
    String? itemName,
    int? quantity,
    double? price,
    double? totalAmount,
    DateTime? dateTime,
    String? type,
  }) {
    return Transaction(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      totalAmount: totalAmount ?? this.totalAmount,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
    );
  }

  // Helper method to check if this is a sale transaction
  bool get isSale => type.toLowerCase() == 'sale';

  // Helper method to check if this is a purchase transaction
  bool get isPurchase => type.toLowerCase() == 'purchase';

  // Helper method to get formatted date string
  String get formattedDate {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Helper method to get formatted date and time string
  String get formattedDateTime {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to get formatted price
  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }

  // Helper method to get formatted total amount
  String get formattedTotal {
    return '₹${totalAmount.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'Transaction{id: $id, itemName: $itemName, quantity: $quantity, totalAmount: $totalAmount, type: $type, dateTime: $dateTime}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}