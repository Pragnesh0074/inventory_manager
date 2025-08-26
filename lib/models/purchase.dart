import 'package:flutter/foundation.dart';

class Purchase {
  final String id;
  final String shopId;
  final String itemId;
  final String itemName;
  final int quantity;
  final double unitPurchasePrice;
  final double totalAmount;
  final String partyName;
  final String partyAddress;
  final double totalPayment; // agreed invoice amount
  final double paidAmount; // paid so far
  final DateTime dateTime;
  final String? note;

  Purchase({
    required this.id,
    required this.shopId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPurchasePrice,
    required this.totalAmount,
    required this.partyName,
    required this.partyAddress,
    required this.totalPayment,
    required this.paidAmount,
    required this.dateTime,
    this.note,
  });

  double get remainingAmount =>
      (totalPayment - paidAmount).clamp(0, double.infinity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'unit_purchase_price': unitPurchasePrice,
      'total_amount': totalAmount,
      'party_name': partyName,
      'party_address': partyAddress,
      'total_payment': totalPayment,
      'paid_amount': paidAmount,
      'date_time': dateTime.toIso8601String(),
      'note': note,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      shopId: map['shop_id'],
      itemId: map['item_id'],
      itemName: map['item_name'],
      quantity: map['quantity'] ?? 0,
      unitPurchasePrice: (map['unit_purchase_price'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      partyName: map['party_name'] ?? '',
      partyAddress: map['party_address'] ?? '',
      totalPayment: (map['total_payment'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      dateTime: DateTime.parse(map['date_time']),
      note: map['note'],
    );
  }

  Purchase copyWith({
    String? id,
    String? shopId,
    String? itemId,
    String? itemName,
    int? quantity,
    double? unitPurchasePrice,
    double? totalAmount,
    String? partyName,
    String? partyAddress,
    double? totalPayment,
    double? paidAmount,
    DateTime? dateTime,
    String? note,
  }) {
    return Purchase(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPurchasePrice: unitPurchasePrice ?? this.unitPurchasePrice,
      totalAmount: totalAmount ?? this.totalAmount,
      partyName: partyName ?? this.partyName,
      partyAddress: partyAddress ?? this.partyAddress,
      totalPayment: totalPayment ?? this.totalPayment,
      paidAmount: paidAmount ?? this.paidAmount,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
    );
  }
}
