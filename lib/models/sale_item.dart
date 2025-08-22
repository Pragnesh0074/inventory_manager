class SaleItem {
  final String itemId;
  final String itemName;
  final int quantity;
  final double originalPrice; // Original item price
  final double salePrice; // Temporary price for this sale (can be different from original)
  final double totalAmount;

  SaleItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.originalPrice,
    required this.salePrice,
    required this.totalAmount,
  });

  // Convert SaleItem to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'original_price': originalPrice,
      'sale_price': salePrice,
      'total_amount': totalAmount,
    };
  }

  // Create SaleItem from database Map
  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      itemId: map['item_id'] ?? '',
      itemName: map['item_name'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      originalPrice: map['original_price']?.toDouble() ?? 0.0,
      salePrice: map['sale_price']?.toDouble() ?? 0.0,
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
    );
  }

  // Convert SaleItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'originalPrice': originalPrice,
      'salePrice': salePrice,
      'totalAmount': totalAmount,
    };
  }

  // Create SaleItem from JSON
  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      quantity: json['quantity']?.toInt() ?? 0,
      originalPrice: json['originalPrice']?.toDouble() ?? 0.0,
      salePrice: json['salePrice']?.toDouble() ?? 0.0,
      totalAmount: json['totalAmount']?.toDouble() ?? 0.0,
    );
  }

  // Create a copy of the sale item with updated fields
  SaleItem copyWith({
    String? itemId,
    String? itemName,
    int? quantity,
    double? originalPrice,
    double? salePrice,
    double? totalAmount,
  }) {
    return SaleItem(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      originalPrice: originalPrice ?? this.originalPrice,
      salePrice: salePrice ?? this.salePrice,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  // Helper method to check if price was modified from original
  bool get isPriceModified => salePrice != originalPrice;

  // Helper method to get formatted original price
  String get formattedOriginalPrice {
    return '₹${originalPrice.toStringAsFixed(2)}';
  }

  // Helper method to get formatted sale price
  String get formattedSalePrice {
    return '₹${salePrice.toStringAsFixed(2)}';
  }

  // Helper method to get formatted total amount
  String get formattedTotal {
    return '₹${totalAmount.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'SaleItem{itemName: $itemName, quantity: $quantity, salePrice: $salePrice, totalAmount: $totalAmount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleItem && 
           other.itemId == itemId &&
           other.quantity == quantity &&
           other.salePrice == salePrice;
  }

  @override
  int get hashCode {
    return itemId.hashCode ^ quantity.hashCode ^ salePrice.hashCode;
  }
}