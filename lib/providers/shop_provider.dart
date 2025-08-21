import 'package:flutter/foundation.dart';
import '../models/shop.dart';
import '../models/inventory_item.dart';
import '../models/stock_entry.dart';
import '../models/transaction.dart';
import '../models/sale_order.dart';
import '../database/database_helper.dart';

class ShopProvider with ChangeNotifier {
  List<Shop> _shops = [];
  Shop? _currentShop;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = false;

  List<Shop> get shops => _shops;
  Shop? get currentShop => _currentShop;
  bool get isLoading => _isLoading;

  // Initialize and load data from database
  Future<void> initializeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _shops = await _databaseHelper.getAllShops();
    } catch (e) {
      print('Error loading shops: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setCurrentShop(Shop shop) {
    _currentShop = shop;
    notifyListeners();
  }

  Future<void> addShop(Shop shop) async {
    try {
      await _databaseHelper.insertShop(shop);
      _shops.add(shop);
      notifyListeners();
    } catch (e) {
      print('Error adding shop: $e');
      throw e;
    }
  }

  Future<void> updateShop(Shop updatedShop) async {
    try {
      await _databaseHelper.updateShop(updatedShop);
      final index = _shops.indexWhere((shop) => shop.id == updatedShop.id);
      if (index != -1) {
        _shops[index] = updatedShop;
        if (_currentShop?.id == updatedShop.id) {
          _currentShop = updatedShop;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error updating shop: $e');
      throw e;
    }
  }

  Future<void> deleteShop(String shopId) async {
    try {
      await _databaseHelper.deleteShop(shopId);
      _shops.removeWhere((shop) => shop.id == shopId);
      if (_currentShop?.id == shopId) {
        _currentShop = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting shop: $e');
      throw e;
    }
  }

  Future<void> addInventoryItem(String shopId, InventoryItem item) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);

      // Check if item already exists
      final existingIndex = shop.inventory.indexWhere(
        (i) => i.name.toLowerCase() == item.name.toLowerCase(),
      );

      if (existingIndex != -1) {
        // Add to existing item
        final existingItem = shop.inventory[existingIndex];
        existingItem.quantity += item.quantity;
        existingItem.lastUpdated = DateTime.now();

        final stockEntry = StockEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          quantity: item.quantity,
          type: 'addition',
          dateTime: DateTime.now(),
          note: 'Stock addition',
        );

        existingItem.stockEntries.add(stockEntry);

        await _databaseHelper.updateInventoryItem(existingItem);
        await _databaseHelper.insertStockEntry(existingItem.id, stockEntry);
      } else {
        // Add new item
        final stockEntry = StockEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          quantity: item.quantity,
          type: 'addition',
          dateTime: DateTime.now(),
          note: 'Initial stock',
        );

        item.stockEntries.add(stockEntry);
        shop.inventory.add(item);

        await _databaseHelper.insertInventoryItem(shopId, item);
        await _databaseHelper.insertStockEntry(item.id, stockEntry);
      }

      notifyListeners();
    } catch (e) {
      print('Error adding inventory item: $e');
      throw e;
    }
  }

  Future<void> updateInventoryItem(
    String shopId,
    InventoryItem updatedItem,
  ) async {
    try {
      await _databaseHelper.updateInventoryItem(updatedItem);
      final shop = _shops.firstWhere((s) => s.id == shopId);
      final index = shop.inventory.indexWhere(
        (item) => item.id == updatedItem.id,
      );
      if (index != -1) {
        shop.inventory[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating inventory item: $e');
      throw e;
    }
  }

  Future<void> deleteInventoryItem(String shopId, String itemId) async {
    try {
      await _databaseHelper.deleteInventoryItem(itemId);
      final shop = _shops.firstWhere((s) => s.id == shopId);
      shop.inventory.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      print('Error deleting inventory item: $e');
      throw e;
    }
  }

  Future<void> sellItem(String shopId, String itemId, int quantity) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      final item = shop.inventory.firstWhere((i) => i.id == itemId);

      if (item.quantity >= quantity) {
        item.quantity -= quantity;
        item.lastUpdated = DateTime.now();

        // Add stock entry
        final stockEntry = StockEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          quantity: quantity,
          type: 'sale',
          dateTime: DateTime.now(),
          note: 'Item sold',
        );

        item.stockEntries.add(stockEntry);

        // Add transaction
        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          itemId: itemId,
          itemName: item.name,
          quantity: quantity,
          price: item.price,
          totalAmount: item.price * quantity,
          dateTime: DateTime.now(),
          type: 'sale',
        );

        shop.transactions.add(transaction);

        // Update database
        await _databaseHelper.updateInventoryItem(item);
        await _databaseHelper.insertStockEntry(item.id, stockEntry);
        await _databaseHelper.insertTransaction(shopId, transaction);

        notifyListeners();
      }
    } catch (e) {
      print('Error selling item: $e');
      throw e;
    }
  }

  Future<void> addStock(String shopId, String itemId, int quantity) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      final item = shop.inventory.firstWhere((i) => i.id == itemId);

      item.quantity += quantity;
      item.lastUpdated = DateTime.now();

      // Add stock entry
      final stockEntry = StockEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        quantity: quantity,
        type: 'addition',
        dateTime: DateTime.now(),
        note: 'Stock addition',
      );

      item.stockEntries.add(stockEntry);

      // Update database
      await _databaseHelper.updateInventoryItem(item);
      await _databaseHelper.insertStockEntry(item.id, stockEntry);

      notifyListeners();
    } catch (e) {
      print('Error adding stock: $e');
      throw e;
    }
  }

  Future<List<Transaction>> getMonthlyTransactions(
    String shopId,
    DateTime month,
  ) async {
    try {
      return await _databaseHelper.getMonthlyTransactions(shopId, month);
    } catch (e) {
      print('Error getting monthly transactions: $e');
      return [];
    }
  }

  // Create a sale order with multiple items
  Future<void> createSaleOrder(String shopId, SaleOrder saleOrder) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);

      // Process each sale item and update inventory
      for (final saleItem in saleOrder.items) {
        final item = shop.inventory.firstWhere((i) => i.id == saleItem.item.id);

        if (item.quantity >= saleItem.quantity) {
          item.quantity -= saleItem.quantity;
          item.lastUpdated = DateTime.now();

          // Add stock entry
          final stockEntry = StockEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            quantity: saleItem.quantity,
            type: 'sale',
            dateTime: DateTime.now(),
            note: 'Item sold in order ${saleOrder.billNumber}',
          );

          item.stockEntries.add(stockEntry);

          // Add individual transaction for tracking
          final transaction = Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            itemId: saleItem.item.id,
            itemName: saleItem.item.name,
            quantity: saleItem.quantity,
            price: saleItem.unitPrice,
            totalAmount: saleItem.totalPrice,
            dateTime: saleOrder.dateTime,
            type: 'sale',
          );

          shop.transactions.add(transaction);

          // Update database
          await _databaseHelper.updateInventoryItem(item);
          await _databaseHelper.insertStockEntry(item.id, stockEntry);
          await _databaseHelper.insertTransaction(shopId, transaction);
        } else {
          throw Exception('Insufficient stock for ${item.name}');
        }
      }

      // Add sale order to shop
      shop.saleOrders.add(saleOrder);

      // Save sale order to database (you'll need to implement this in DatabaseHelper)
      // await _databaseHelper.insertSaleOrder(saleOrder);

      notifyListeners();
    } catch (e) {
      print('Error creating sale order: $e');
      throw e;
    }
  }

  // Get all sale orders for a shop
  List<SaleOrder> getSaleOrders(String shopId) {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      return shop.saleOrders;
    } catch (e) {
      print('Error getting sale orders: $e');
      return [];
    }
  }

  // Get sale orders for a specific month
  List<SaleOrder> getMonthlySaleOrders(String shopId, DateTime month) {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      return shop.saleOrders.where((order) {
        return order.dateTime.year == month.year &&
            order.dateTime.month == month.month;
      }).toList();
    } catch (e) {
      print('Error getting monthly sale orders: $e');
      return [];
    }
  }
}
