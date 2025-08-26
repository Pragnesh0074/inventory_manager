import 'package:inventory_manager/models/stock_entry.dart';

class InventoryItem {
  final String id;
  final String name;
  final double sellingPrice; // Price at which item is sold
  final double? purchasePrice; // Price at which item was purchased (optional for backward compatibility)
  int quantity;
  final DateTime createdDate;
  DateTime lastUpdated;
  List<StockEntry> stockEntries;

  // Backward compatibility getter
  double get price => sellingPrice;

  // Calculate profit margin if both prices are available
  double? get profitMargin => purchasePrice != null ? sellingPrice - purchasePrice! : null;
  double? get profitPercentage => purchasePrice != null && purchasePrice! > 0 
    ? ((sellingPrice - purchasePrice!) / purchasePrice!) * 100 : null;

  InventoryItem({
    required this.id,
    required this.name,
    required this.sellingPrice,
    this.purchasePrice,
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
      'sellingPrice': sellingPrice,
      'purchasePrice': purchasePrice,
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
      sellingPrice: json['sellingPrice']?.toDouble() ?? json['price']?.toDouble() ?? 0.0, // Backward compatibility
      purchasePrice: json['purchasePrice']?.toDouble(),
      quantity: json['quantity'],
      createdDate: DateTime.parse(json['createdDate']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      stockEntries: (json['stockEntries'] as List)
          .map((entry) => StockEntry.fromJson(entry))
          .toList(),
    );
  }
}