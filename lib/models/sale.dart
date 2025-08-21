import 'sale_item.dart';
import 'additional_cost.dart';

class Sale {
  final String id;
  final String shopId;
  final List<SaleItem> items;
  final List<AdditionalCost> additionalCosts;
  final double subtotal; // Total of all items
  final double additionalCostsTotal; // Total of additional costs
  final double grandTotal; // Subtotal + additional costs
  final DateTime dateTime;
  final String? notes;

  Sale({
    required this.id,
    required this.shopId,
    required this.items,
    required this.additionalCosts,
    required this.subtotal,
    required this.additionalCostsTotal,
    required this.grandTotal,
    required this.dateTime,
    this.notes,
  });

  // Convert Sale to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'items': items.map((item) => item.toMap()).toList(),
      'additional_costs': additionalCosts.map((cost) => cost.toMap()).toList(),
      'subtotal': subtotal,
      'additional_costs_total': additionalCostsTotal,
      'grand_total': grandTotal,
      'date_time': dateTime.toIso8601String(),
      'notes': notes,
    };
  }

  // Create Sale from database Map
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] ?? '',
      shopId: map['shop_id'] ?? '',
      items: (map['items'] as List? ?? [])
          .map((item) => SaleItem.fromMap(item))
          .toList(),
      additionalCosts: (map['additional_costs'] as List? ?? [])
          .map((cost) => AdditionalCost.fromMap(cost))
          .toList(),
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      additionalCostsTotal: map['additional_costs_total']?.toDouble() ?? 0.0,
      grandTotal: map['grand_total']?.toDouble() ?? 0.0,
      dateTime: DateTime.parse(map['date_time'] ?? DateTime.now().toIso8601String()),
      notes: map['notes'],
    );
  }

  // Convert Sale to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'items': items.map((item) => item.toJson()).toList(),
      'additionalCosts': additionalCosts.map((cost) => cost.toJson()).toList(),
      'subtotal': subtotal,
      'additionalCostsTotal': additionalCostsTotal,
      'grandTotal': grandTotal,
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
    };
  }

  // Create Sale from JSON
  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] ?? '',
      shopId: json['shopId'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => SaleItem.fromJson(item))
          .toList(),
      additionalCosts: (json['additionalCosts'] as List? ?? [])
          .map((cost) => AdditionalCost.fromJson(cost))
          .toList(),
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      additionalCostsTotal: json['additionalCostsTotal']?.toDouble() ?? 0.0,
      grandTotal: json['grandTotal']?.toDouble() ?? 0.0,
      dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
    );
  }

  // Create a copy of the sale with updated fields
  Sale copyWith({
    String? id,
    String? shopId,
    List<SaleItem>? items,
    List<AdditionalCost>? additionalCosts,
    double? subtotal,
    double? additionalCostsTotal,
    double? grandTotal,
    DateTime? dateTime,
    String? notes,
  }) {
    return Sale(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      items: items ?? this.items,
      additionalCosts: additionalCosts ?? this.additionalCosts,
      subtotal: subtotal ?? this.subtotal,
      additionalCostsTotal: additionalCostsTotal ?? this.additionalCostsTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
    );
  }

  // Factory method to create a sale and calculate totals
  factory Sale.create({
    required String id,
    required String shopId,
    required List<SaleItem> items,
    required List<AdditionalCost> additionalCosts,
    required DateTime dateTime,
    String? notes,
  }) {
    final subtotal = items.fold(0.0, (sum, item) => sum + item.totalAmount);
    final additionalCostsTotal = additionalCosts.fold(0.0, (sum, cost) => sum + cost.amount);
    final grandTotal = subtotal + additionalCostsTotal;

    return Sale(
      id: id,
      shopId: shopId,
      items: items,
      additionalCosts: additionalCosts,
      subtotal: subtotal,
      additionalCostsTotal: additionalCostsTotal,
      grandTotal: grandTotal,
      dateTime: dateTime,
      notes: notes,
    );
  }

  // Helper method to get total quantity of items
  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Helper method to check if any item has modified price
  bool get hasModifiedPrices {
    return items.any((item) => item.isPriceModified);
  }

  // Helper method to get formatted date string
  String get formattedDate {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Helper method to get formatted date and time string
  String get formattedDateTime {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to get formatted subtotal
  String get formattedSubtotal {
    return '₹${subtotal.toStringAsFixed(2)}';
  }

  // Helper method to get formatted additional costs total
  String get formattedAdditionalCostsTotal {
    return '₹${additionalCostsTotal.toStringAsFixed(2)}';
  }

  // Helper method to get formatted grand total
  String get formattedGrandTotal {
    return '₹${grandTotal.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'Sale{id: $id, items: ${items.length}, grandTotal: $grandTotal, dateTime: $dateTime}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sale && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}