import 'package:stockly/models/purchase.dart';
import 'package:stockly/models/sale_record.dart';

class ItemStatistics {
  final String itemId;
  final String itemName;
  final int currentQuantity;
  double averagePurchasePrice;
  int totalPurchaseQuantity;
  double totalPurchaseAmount;
  int totalSaleQuantity;
  double totalSaleAmount;
  double averageSalePrice;
  double totalProfit;
  double profitMargin;
  final List<Purchase> purchaseHistory;
  final List<SaleRecord> saleHistory;

  ItemStatistics({
    required this.itemId,
    required this.itemName,
    required this.currentQuantity,
    required this.averagePurchasePrice,
    required this.totalPurchaseQuantity,
    required this.totalPurchaseAmount,
    required this.totalSaleQuantity,
    required this.totalSaleAmount,
    required this.averageSalePrice,
    required this.totalProfit,
    required this.profitMargin,
    required this.purchaseHistory,
    required this.saleHistory,
  });
}