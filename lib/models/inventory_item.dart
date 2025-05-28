import 'package:inventory_manager/models/stock_entry.dart';

class InventoryItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final DateTime createdDate;
  DateTime lastUpdated;
  List<StockEntry> stockEntries;

  InventoryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.createdDate,
    DateTime? lastUpdated,
    List<StockEntry>? stockEntries,
  }) : lastUpdated = lastUpdated ?? DateTime.now(),
        stockEntries = stockEntries ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'createdDate': createdDate.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'stockEntries': stockEntries.map((entry) => entry.toJson()).toList(),
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      createdDate: DateTime.parse(json['createdDate']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      stockEntries: (json['stockEntries'] as List)
          .map((entry) => StockEntry.fromJson(entry))
          .toList(),
    );
  }
}