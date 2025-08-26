import 'purchase_party.dart';

class Purchase {
  final String id;
  final String itemId;
  final String itemName;
  final String purchasePartyId;
  final int quantity;
  final double purchasePrice; // per unit purchase price
  final double totalAmount; // quantity * purchasePrice
  final double paidAmount;
  final double remainingAmount;
  final DateTime purchaseDate;
  final String? notes;
  final DateTime createdDate;
  DateTime lastUpdated;
  
  // Optional reference to purchase party (for display purposes)
  PurchaseParty? purchaseParty;

  Purchase({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.purchasePartyId,
    required this.quantity,
    required this.purchasePrice,
    required this.totalAmount,
    required this.paidAmount,
    required this.purchaseDate,
    this.notes,
    required this.createdDate,
    DateTime? lastUpdated,
    this.purchaseParty,
  }) : remainingAmount = totalAmount - paidAmount,
       lastUpdated = lastUpdated ?? DateTime.now();

  bool get isFullyPaid => remainingAmount <= 0;
  bool get isPartiallyPaid => paidAmount > 0 && remainingAmount > 0;
  bool get isUnpaid => paidAmount <= 0;

  Purchase copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? purchasePartyId,
    int? quantity,
    double? purchasePrice,
    double? totalAmount,
    double? paidAmount,
    DateTime? purchaseDate,
    String? notes,
    DateTime? createdDate,
    DateTime? lastUpdated,
    PurchaseParty? purchaseParty,
  }) {
    return Purchase(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      purchasePartyId: purchasePartyId ?? this.purchasePartyId,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      createdDate: createdDate ?? this.createdDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      purchaseParty: purchaseParty ?? this.purchaseParty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'purchasePartyId': purchasePartyId,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'purchaseDate': purchaseDate.toIso8601String(),
      'notes': notes,
      'createdDate': createdDate.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      itemId: json['itemId'],
      itemName: json['itemName'],
      purchasePartyId: json['purchasePartyId'],
      quantity: json['quantity'],
      purchasePrice: json['purchasePrice'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      paidAmount: json['paidAmount'].toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate']),
      notes: json['notes'],
      createdDate: DateTime.parse(json['createdDate']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}