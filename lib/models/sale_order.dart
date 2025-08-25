import 'inventory_item.dart';

class SaleItem {
  final InventoryItem? item; // Can be null for temporary items
  final String? temporaryItemName; // Name for temporary items
  final double? temporaryItemPrice; // Price for temporary items
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  SaleItem({
    this.item,
    this.temporaryItemName,
    this.temporaryItemPrice,
    required this.quantity,
    required this.unitPrice,
  }) : totalPrice = unitPrice * quantity,
       assert(
         (item != null) ||
             (temporaryItemName != null && temporaryItemPrice != null),
         'Either item or temporary item details must be provided',
       );

  // Check if this is a temporary item
  bool get isTemporaryItem => item == null;

  // Get the item name
  String get itemName => item?.name ?? temporaryItemName!;

  Map<String, dynamic> toMap() {
    return {
      'item_id': item?.id ?? '',
      'item_name': itemName,
      'temporary_item_name': temporaryItemName,
      'temporary_item_price': temporaryItemPrice,
      'is_temporary': isTemporaryItem,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map, InventoryItem? item) {
    final isTemporary = map['is_temporary'] ?? false;

    if (isTemporary) {
      return SaleItem(
        temporaryItemName: map['temporary_item_name'] ?? '',
        temporaryItemPrice: map['temporary_item_price']?.toDouble() ?? 0.0,
        quantity: map['quantity'] ?? 0,
        unitPrice: map['unit_price']?.toDouble() ?? 0.0,
      );
    } else {
      return SaleItem(
        item: item,
        quantity: map['quantity'] ?? 0,
        unitPrice: map['unit_price']?.toDouble() ?? 0.0,
      );
    }
  }
}

class AdditionalCharge {
  final String name;
  final double amount;
  final String id;

  AdditionalCharge({required this.name, required this.amount})
    : id = DateTime.now().millisecondsSinceEpoch.toString();

  double get totalAmount => amount;

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'amount': amount};
  }

  factory AdditionalCharge.fromMap(Map<String, dynamic> map) {
    return AdditionalCharge(
      name: map['name'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
    );
  }
}

class SaleOrder {
  final String id;
  final String shopId;
  final List<SaleItem> items;
  final List<AdditionalCharge> additionalCharges;
  final String customerName;
  final String customerPhone;
  final DateTime dateTime;
  final double subtotal;
  final double tax;
  final double total;
  final String billNumber;

  SaleOrder({
    required this.id,
    required this.shopId,
    required this.items,
    this.additionalCharges = const [],
    required this.customerName,
    required this.customerPhone,
    required this.dateTime,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.billNumber,
  });

  // Get total quantity of all items
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  // Get item count (number of different items)
  int get itemCount => items.length;

  // Get formatted date
  String get formattedDate =>
      '${dateTime.day}/${dateTime.month}/${dateTime.year}';

  // Get formatted date and time
  String get formattedDateTime =>
      '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  // Get formatted total amount
  String get formattedTotal => '₹${total.toStringAsFixed(2)}';

  // Get formatted subtotal
  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(2)}';

  // Get formatted tax
  String get formattedTax => '₹${tax.toStringAsFixed(2)}';

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'date_time': dateTime.toIso8601String(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'bill_number': billNumber,
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'items': items.map((item) => item.toMap()).toList(),
      'additionalCharges':
          additionalCharges.map((charge) => charge.toMap()).toList(),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'dateTime': dateTime.toIso8601String(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'billNumber': billNumber,
    };
  }

  // Create from JSON
  factory SaleOrder.fromJson(Map<String, dynamic> json) {
    return SaleOrder(
      id: json['id'] ?? '',
      shopId: json['shopId'] ?? '',
      items:
          json['items'] != null
              ? (json['items'] as List).map((itemJson) {
                // Create a minimal InventoryItem for the SaleItem
                final item = InventoryItem(
                  id: itemJson['item_id'] ?? '',
                  name: itemJson['item_name'] ?? '',
                  price: itemJson['unit_price']?.toDouble() ?? 0.0,
                  quantity: 0,
                  createdDate: DateTime.now(),
                  lastUpdated: DateTime.now(),
                );
                return SaleItem.fromMap(itemJson, item);
              }).toList()
              : [],
      additionalCharges:
          json['additionalCharges'] != null
              ? (json['additionalCharges'] as List).map((chargeJson) {
                return AdditionalCharge.fromMap(chargeJson);
              }).toList()
              : [],
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      dateTime: DateTime.parse(
        json['dateTime'] ?? DateTime.now().toIso8601String(),
      ),
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      tax: json['tax']?.toDouble() ?? 0.0,
      total: json['total']?.toDouble() ?? 0.0,
      billNumber: json['billNumber'] ?? '',
    );
  }

  // Create copy with updated fields
  SaleOrder copyWith({
    String? id,
    String? shopId,
    List<SaleItem>? items,
    List<AdditionalCharge>? additionalCharges,
    String? customerName,
    String? customerPhone,
    DateTime? dateTime,
    double? subtotal,
    double? tax,
    double? total,
    String? billNumber,
  }) {
    return SaleOrder(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      items: items ?? this.items,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      dateTime: dateTime ?? this.dateTime,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      billNumber: billNumber ?? this.billNumber,
    );
  }

  @override
  String toString() {
    return 'SaleOrder{id: $id, billNumber: $billNumber, customerName: $customerName, total: $total, dateTime: $dateTime}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleOrder && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
