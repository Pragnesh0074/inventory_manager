import 'package:inventory_manager/models/transaction.dart';
import 'package:inventory_manager/models/sale_order.dart';

import 'inventory_item.dart';

class Shop {
  final String id;
  final String name;
  final String address;
  final DateTime createdDate;
  final double gstPercentage;
  List<InventoryItem> inventory;
  List<Transaction> transactions;
  List<SaleOrder> saleOrders;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.createdDate,
    this.gstPercentage = 18.0,
    List<InventoryItem>? inventory,
    List<Transaction>? transactions,
    List<SaleOrder>? saleOrders,
  }) : inventory = inventory ?? [],
       transactions = transactions ?? [],
       saleOrders = saleOrders ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'created_date': createdDate.toIso8601String(),
      'gst_percentage': gstPercentage,
      'inventory': inventory.map((item) => item.toJson()).toList(),
      'transactions': transactions.map((trans) => trans.toJson()).toList(),
      'sale_orders': saleOrders.map((order) => order.toJson()).toList(),
    };
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      createdDate: DateTime.parse(json['created_date'] ?? json['createdDate']),
      gstPercentage: json['gst_percentage']?.toDouble() ?? 18.0,
      inventory:
          json['inventory'] != null
              ? (json['inventory'] as List)
                  .map((item) => InventoryItem.fromJson(item))
                  .toList()
              : [],
      transactions:
          json['transactions'] != null
              ? (json['transactions'] as List)
                  .map((trans) => Transaction.fromJson(trans))
                  .toList()
              : [],
      saleOrders:
          json['sale_orders'] != null
              ? (json['sale_orders'] as List)
                  .map((order) => SaleOrder.fromJson(order))
                  .toList()
              : [],
    );
  }

  // Database mapping methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'created_date': createdDate.toIso8601String(),
      'gst_percentage': gstPercentage,
    };
  }

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      createdDate: DateTime.parse(map['created_date']),
      gstPercentage: map['gst_percentage']?.toDouble() ?? 18.0,
    );
  }
}
