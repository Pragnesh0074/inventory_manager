import 'package:inventory_manager/models/transaction.dart';

import 'inventory_item.dart';

class Shop {
  final String id;
  final String name;
  final String address;
  final DateTime createdDate;
  List<InventoryItem> inventory;
  List<Transaction> transactions;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.createdDate,
    List<InventoryItem>? inventory,
    List<Transaction>? transactions,
  }) : inventory = inventory ?? [],
        transactions = transactions ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'created_date': createdDate.toIso8601String(),
      'inventory': inventory.map((item) => item.toJson()).toList(),
      'transactions': transactions.map((trans) => trans.toJson()).toList(),
    };
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      createdDate: DateTime.parse(json['created_date'] ?? json['createdDate']),
      inventory: json['inventory'] != null
          ? (json['inventory'] as List)
          .map((item) => InventoryItem.fromJson(item))
          .toList()
          : [],
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
          .map((trans) => Transaction.fromJson(trans))
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
    };
  }

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      createdDate: DateTime.parse(map['created_date']),
    );
  }
}